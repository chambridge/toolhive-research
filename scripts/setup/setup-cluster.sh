#!/bin/bash
set -euo pipefail

# Toolhive MCP Registry - Cluster Setup Script
# Automates the complete setup of kind cluster with Toolhive operator

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Configuration
KIND_CONFIG="${PROJECT_ROOT}/deploy/kubernetes/kind-config.yaml"
CLUSTER_NAME="toolhive-cluster"

echo "🚀 Setting up Toolhive MCP Registry environment..."

# Check prerequisites
echo "📋 Checking prerequisites..."
for cmd in kind kubectl helm; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "❌ $cmd is required but not installed"
        exit 1
    fi
    echo "✅ $cmd: $(command -v "$cmd")"
done

# Check container runtime
if command -v podman &> /dev/null; then
    echo "✅ Podman found, setting as preferred runtime"
    export KIND_EXPERIMENTAL_PROVIDER=podman
elif command -v docker &> /dev/null; then
    echo "✅ Docker found, using as runtime"
    unset KIND_EXPERIMENTAL_PROVIDER
else
    echo "❌ Neither Podman nor Docker found"
    exit 1
fi

# Create kind cluster
echo "🏗️ Creating kind cluster..."
if kind get clusters | grep -q "$CLUSTER_NAME"; then
    echo "ℹ️ Cluster $CLUSTER_NAME already exists"
    read -p "Delete and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kind delete cluster --name "$CLUSTER_NAME"
        kind create cluster --config "$KIND_CONFIG"
    fi
else
    kind create cluster --config "$KIND_CONFIG"
fi

# Wait for cluster to be ready
echo "⏳ Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Install Toolhive CRDs
echo "📦 Installing Toolhive CRDs..."
helm upgrade -i toolhive-operator-crds \
    oci://ghcr.io/stacklok/toolhive/toolhive-operator-crds

# Install Toolhive Operator
echo "⚙️ Installing Toolhive Operator..."
helm upgrade -i toolhive-operator \
    oci://ghcr.io/stacklok/toolhive/toolhive-operator \
    -n toolhive-system --create-namespace

# Wait for operator to be ready
echo "⏳ Waiting for operator to be ready..."
kubectl wait --for=condition=Available deployment/toolhive-operator \
    -n toolhive-system --timeout=300s

echo "✅ Toolhive cluster setup complete!"
echo ""
echo "Next steps:"
echo "1. Configure registry: thv config set-registry \$(pwd)/registry/registry.json"
echo "2. Deploy servers: thv run osv-scanner"
echo "3. View status: kubectl get mcpservers -A"