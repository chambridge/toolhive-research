# Toolhive Model Context Protocol Registry Setup

## Complete Implementation Guide

This repository contains a comprehensive implementation of a custom Toolhive Model Context Protocol (MCP) Registry, including Kubernetes operator deployment and CLI-based registry management.

## 🎯 Project Overview

**Objective**: Setup a kind cluster, deploy the Toolhive operator, and create a custom MCP registry with tested server configurations.

**Status**: ✅ **COMPLETED** - All phases successfully implemented and tested

## 📋 Project Structure

```
toolhive-mcp-registry/
├── README.md                          # Complete setup documentation
├── docs/                              # Documentation
│   ├── guides/                        # Setup and configuration guides
│   │   ├── tasks.md                   # Detailed task breakdown
│   │   ├── registry-plan.md          # Registry planning documentation
│   │   └── server-documentation.md   # Server configuration docs
│   ├── troubleshooting/               # Troubleshooting resources
│   │   ├── TROUBLESHOOTING.md        # Common issues and solutions
│   │   ├── ALPHA-LIMITATIONS.md      # Alpha-stage limitations
│   │   └── DEVIATIONS.md             # Implementation deviations
│   └── architecture/                  # Architecture documentation
│       ├── mcp-server-research.md    # MCP server deployment research
│       └── operator-validation-results.md  # Operator validation
├── deploy/                            # Deployment resources
│   ├── kubernetes/                    # Kubernetes manifests
│   │   ├── kind-config.yaml          # Kind cluster configuration
│   │   ├── osv-mcpserver.yaml        # MCPServer example
│   │   └── test-mcpserver.yaml       # Test MCPServer configuration
│   └── helm/                          # Helm deployment guides
│       └── toolhive-operator-notes.md # Operator installation notes
├── registry/                          # MCP Registry implementation
│   ├── registry.json                 # Main registry file
│   ├── schemas/                       # Schema definitions
│   │   └── schema.json               # Official registry schema
│   ├── examples/                      # Registry examples
│   │   └── official-registry.json    # Official registry reference
│   └── .secrets/                      # Secret management (gitignored)
├── scripts/                           # Automation scripts
│   ├── setup/                         # Setup automation
│   └── validation/                    # Validation scripts
├── examples/                          # Configuration examples
│   ├── basic/                         # Basic configuration examples
│   └── advanced/                      # Advanced configuration examples
│       └── advanced-config-examples.md
└── tests/                             # Test suites
    ├── unit/                          # Unit tests
    └── integration/                   # Integration tests
        └── end-to-end-test-results.md # Testing results
```

## 🚀 Quick Start

### Prerequisites
- macOS/Linux with Docker or Podman installed
- kubectl, Helm, and kind installed
- 8GB+ RAM available for kind cluster

### 1. Clone and Setup
```bash
git clone git@github.com:chambridge/toolhive-research.git
cd toolhive-research

# Make scripts executable
chmod +x scripts/setup/*.sh scripts/validation/*.sh
```

### 2. Create Kind Cluster
```bash
export KIND_EXPERIMENTAL_PROVIDER=podman  # or remove for Docker
kind create cluster --config deploy/kubernetes/kind-config.yaml
```

### 3. Deploy Toolhive Operator
```bash
# Install CRDs
helm upgrade -i toolhive-operator-crds oci://ghcr.io/stacklok/toolhive/toolhive-operator-crds

# Install Operator
helm upgrade -i toolhive-operator oci://ghcr.io/stacklok/toolhive/toolhive-operator -n toolhive-system --create-namespace
```

### 4. Install ToolHive CLI
```bash
# Use automated installation script
./scripts/setup/install-toolhive-cli.sh

# OR manual installation for macOS ARM64 (adjust for your platform)
curl -L -o toolhive.tar.gz https://github.com/stacklok/toolhive/releases/download/v0.3.5/toolhive_0.3.5_darwin_arm64.tar.gz
tar -xzf toolhive.tar.gz
cp thv ~/bin/  # Ensure ~/bin is in PATH
```

### 5. Create Secrets and Configure Registry
```bash
# Create secrets directory and example secrets file
mkdir -p registry/.secrets
cat > registry/.secrets/gofetch-secrets.env << EOF
API_KEY=your-actual-api-key-here
USER_AGENT=YourApp/1.0
MAX_RETRIES=3
EOF

# Configure registry
thv config set-registry registry/registry.json
thv registry list
```

### 6. Deploy MCP Servers
```bash
# From registry
thv run osv-scanner
thv run gofetch

# With advanced features (ensure you've created the secrets file above)
thv run gofetch --env-file registry/.secrets/gofetch-secrets.env --otel-tracing-enabled
```

## 📋 Complete Setup Example

Here's a complete copy-paste example for the entire setup:

```bash
# 1. Clone repository
git clone git@github.com:chambridge/toolhive-research.git
cd toolhive-research
chmod +x scripts/setup/*.sh scripts/validation/*.sh

# 2. Setup container runtime preference (optional)
export KIND_EXPERIMENTAL_PROVIDER=podman  # Use Podman if available

# 3. Create cluster and deploy operator (automated)
./scripts/setup/setup-cluster.sh

# 4. Install ToolHive CLI (automated)
./scripts/setup/install-toolhive-cli.sh

# 5. Create secrets
mkdir -p registry/.secrets
cat > registry/.secrets/gofetch-secrets.env << 'EOF'
API_KEY=your-actual-api-key-here
USER_AGENT=YourApp/1.0
MAX_RETRIES=3
EOF
chmod 600 registry/.secrets/gofetch-secrets.env

# 6. Configure registry
thv config set-registry registry/registry.json
thv registry list

# 7. Deploy servers
thv run osv-scanner
thv run gofetch --env-file registry/.secrets/gofetch-secrets.env

# 8. Verify deployment
# For ToolHive CLI deployments (containers):
thv ls

# For Kubernetes MCPServer deployments (when using kubectl apply):
kubectl get mcpservers -A

# 9. Test connectivity (run in separate terminal)
# kubectl port-forward service/mcp-osv-server-proxy 8080:8080
# curl http://localhost:8080/health
```

### Alternative: Manual Step-by-Step

If you prefer manual control over each step:

```bash
# Manual cluster setup
export KIND_EXPERIMENTAL_PROVIDER=podman
kind create cluster --config deploy/kubernetes/kind-config.yaml

# Manual operator installation
helm upgrade -i toolhive-operator-crds oci://ghcr.io/stacklok/toolhive/toolhive-operator-crds
helm upgrade -i toolhive-operator oci://ghcr.io/stacklok/toolhive/toolhive-operator -n toolhive-system --create-namespace

# Manual CLI installation (macOS ARM64)
curl -L -o toolhive.tar.gz https://github.com/stacklok/toolhive/releases/download/v0.3.5/toolhive_0.3.5_darwin_arm64.tar.gz
tar -xzf toolhive.tar.gz
mkdir -p ~/bin
cp thv ~/bin/
export PATH="$HOME/bin:$PATH"
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc  # or ~/.bashrc
```

## 📊 Implementation Summary

### ✅ Phase 1: Environment Setup
- **Kind Cluster**: 3-node cluster (1 control-plane, 2 workers) using Podman
- **Tools Verified**: kubectl v1.33.1, Helm v3.17.0, Podman 5.6.0
- **Network Configuration**: Port forwarding for ingress traffic

### ✅ Phase 2: Toolhive Operator Deployment  
- **CRDs Installed**: MCPServer, MCPRegistry, MCPToolConfig (v1alpha1)
- **Operator Version**: v0.3.5 in `toolhive-system` namespace
- **Validation**: Health checks, leader election, controller startup confirmed

### ✅ Phase 3: MCP Server Setup
- **MCPServer Deployment**: OSV scanner successfully deployed via Kubernetes CRD
- **Transport Protocols**: streamable-http and stdio+SSE validated
- **Container Management**: Automatic RBAC, service, and pod creation

### ✅ Phase 4: Custom Registry Implementation
- **Registry Structure**: Schema-compliant JSON with 2 tested servers
- **Server Groups**: Organized by functionality (security-tools, web-tools)
- **Advanced Features**: Environment variables, secret management, monitoring

### ✅ Phase 5: Integration and Testing
- **CLI Integration**: ToolHive CLI v0.3.5 configured with custom registry
- **End-to-End Testing**: Both servers deployed and tested successfully
- **Monitoring**: OpenTelemetry tracing and logging validated

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────┐
│            Custom Registry              │
│          (registry.json)                │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│           ToolHive CLI                  │
│             (thv)                       │
└─────────────────┬───────────────────────┘
                  │
    ┌─────────────▼──────────────┐
    │     Container Runtime      │
    │      (Podman/Docker)       │
    └─────────────┬──────────────┘
                  │
┌─────────────────▼───────────────────────┐
│          MCP Server Containers          │
│  ┌─────────────┐  ┌─────────────────┐   │
│  │ OSV Scanner │  │    GoFetch      │   │
│  │    :21519   │  │    :60455       │   │
│  └─────────────┘  └─────────────────┘   │
└─────────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│        MCP Clients                      │
│  (Claude Code, Cursor, etc.)            │
└─────────────────────────────────────────┘
```

## 🔧 Server Configurations

### OSV Scanner (Security Tools)
- **Image**: `ghcr.io/stackloklabs/osv-mcp/server`
- **Transport**: streamable-http
- **Tools**: vulnerability-scan, security-analysis, osv-query
- **Network**: Full outbound access for vulnerability database queries

### GoFetch (Web Tools)  
- **Image**: `ghcr.io/stackloklabs/gofetch/server:latest`
- **Transport**: stdio with SSE proxy
- **Tools**: web-fetch, http-request, url-get
- **Network**: Full outbound access for web content retrieval

## 🔐 Security Features

### Secret Management
- **Gitignored Secrets**: `.secrets/` directory excluded from version control
- **Environment Files**: Secure loading via `--env-file`
- **Schema Support**: Secret variables marked in registry

**⚠️ Important**: The `.secrets/` directory is not included in the repository for security. You must create it and populate with your actual credentials:

```bash
# Create secrets directory
mkdir -p registry/.secrets

# Create secrets file with your actual values
cat > registry/.secrets/gofetch-secrets.env << EOF
API_KEY=your-actual-api-key-here
USER_AGENT=YourApp/1.0
MAX_RETRIES=3
EOF

# Secure the secrets file
chmod 600 registry/.secrets/gofetch-secrets.env
```

### Container Security
- **Minimal Images**: No debugging tools for reduced attack surface
- **Network Isolation**: Configurable outbound access permissions
- **RBAC**: Automatic Kubernetes role-based access control

### Registry Security
- **Schema Validation**: Full compliance with official Stacklok schema
- **Image Verification**: Warnings for unsigned container images
- **Access Control**: File-based permissions for registry access

## 📈 Monitoring and Observability

### OpenTelemetry Integration
```bash
# Distributed tracing
thv run server --otel-tracing-enabled --otel-service-name=custom-name

# Prometheus metrics
thv run server --otel-enable-prometheus-metrics-path --otel-metrics-enabled
```

### Logging
- **Automatic Logging**: All workloads logged to system directories
- **Structured Format**: JSON logs for easy parsing
- **Log Rotation**: Built-in log management

## ⚠️ Known Limitations

### Alpha-Stage Warnings
- **Experimental Status**: Toolhive operator not recommended for production
- **API Stability**: MCPServer CRD in v1alpha1 - breaking changes expected
- **Version Mismatches**: Operator (v0.3.5) and Helm chart (0.2.18) versions differ

### Current Constraints
- **Container Debugging**: Minimal containers lack debugging tools (security feature)
- **Network Permissions**: Currently using `insecure_allow_all` (production should use allowlists)
- **Image Provenance**: Community images lack cryptographic signatures

## 🛠️ Troubleshooting

### Common Issues

#### 1. Kind Cluster Creation Fails
```bash
# Check container runtime
podman --version || docker --version

# Verify kind configuration
kind create cluster --config deploy/kubernetes/kind-config.yaml --dry-run
```

#### 2. Operator Deployment Issues
```bash
# Check CRDs installation
kubectl get crd | grep toolhive

# Verify operator status
kubectl get pods -n toolhive-system
kubectl logs -n toolhive-system -l app.kubernetes.io/name=toolhive-operator
```

#### 3. Registry Configuration Problems
```bash
# Validate registry syntax
python3 -m json.tool registry.json

# Test registry loading
thv config get-registry
thv registry list
```

#### 4. MCP Server Deployment Failures
```bash
# Check workload status
thv ls

# View container logs
podman logs <container-name>

# Test connectivity
curl -s http://127.0.0.1:<port>/health
```

### Debug Commands

Copy-paste debugging commands:

```bash
# Quick system health check
kubectl cluster-info
kubectl get nodes
kubectl get pods -A | grep -E "(FAILED|ERROR|CrashLoop)"

# ToolHive operator status
kubectl get pods -n toolhive-system
kubectl logs -n toolhive-system -l app.kubernetes.io/name=toolhive-operator --tail=20

# MCP server status
kubectl get mcpservers -A
thv ls

# Registry validation
./scripts/validation/validate-registry.sh
thv config get-registry
thv registry list

# Container runtime check
podman ps -a  # or docker ps -a
podman logs osv-scanner 2>/dev/null || docker logs osv-scanner 2>/dev/null

# Network connectivity test
curl -s http://localhost:8080/health || echo "Port forward not running"

# Complete diagnostic collection
echo "=== System Info ===" > debug-info.txt
uname -a >> debug-info.txt
kubectl version --client >> debug-info.txt
thv version >> debug-info.txt
echo "" >> debug-info.txt
echo "=== Cluster Status ===" >> debug-info.txt
kubectl get pods -A >> debug-info.txt
echo "" >> debug-info.txt
echo "=== ToolHive Status ===" >> debug-info.txt
thv ls >> debug-info.txt
echo "Debug info saved to debug-info.txt"
```

## 🎯 Production Deployment Recommendations

### Security Hardening
1. **Network Restrictions**: Replace `insecure_allow_all` with specific host allowlists
2. **Image Signing**: Implement Sigstore signatures for container verification
3. **Secret Management**: Integrate with HashiCorp Vault or Kubernetes secrets
4. **RBAC Policies**: Implement least-privilege access controls

### Scalability
1. **Resource Limits**: Define CPU/memory limits for production workloads
2. **Load Balancing**: Deploy multiple instances with load balancers
3. **Auto-scaling**: Implement horizontal pod autoscaling
4. **Monitoring**: Full observability with Prometheus/Grafana

### Registry Management
1. **Version Control**: Git-based registry management with CI/CD
2. **Testing Pipeline**: Automated server deployment testing
3. **Schema Validation**: Continuous schema compliance checking
4. **Access Control**: Enterprise authentication and authorization

## 📚 Documentation References

- [Official Toolhive Documentation](https://docs.stacklok.com/toolhive/)
- [MCP Protocol Specification](https://modelcontextprotocol.io/)
- [Kind Cluster Setup](https://kind.sigs.k8s.io/)
- [Helm Package Manager](https://helm.sh/)

## 🤝 Contributing

1. Follow the task-driven approach outlined in `docs/guides/tasks.md`
2. Validate all registry changes against the official schema
3. Test deployments in kind cluster before production
4. Document any deviations or workarounds
5. Maintain security best practices for secret management

## 📄 License

This implementation follows the MIT License. See individual component licenses for third-party tools.

---

**Project Status**: ✅ Production-Ready Development Environment  
**Last Updated**: 2025-09-23  
**Toolhive Version**: v0.3.5  
**Registry Version**: 1.0.0