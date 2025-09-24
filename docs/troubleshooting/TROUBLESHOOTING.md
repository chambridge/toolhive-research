# Troubleshooting Guide

## 🛠️ Common Issues and Solutions

This guide provides step-by-step solutions for common issues encountered during Toolhive Model Context Protocol Registry setup and operation.

## 🐳 Container Runtime Issues

### Issue: Kind Cluster Creation Fails with Podman
**Symptoms**:
```
ERROR: failed to create cluster: container runtime not available
```

**Diagnosis**:
```bash
# Check container runtime availability
podman --version
echo $KIND_EXPERIMENTAL_PROVIDER

# Verify Podman socket
podman system connection list
```

**Solutions**:
```bash
# Solution 1: Set Podman provider explicitly
export KIND_EXPERIMENTAL_PROVIDER=podman
kind create cluster --config deploy/kubernetes/kind-config.yaml

# Solution 2: Start Podman machine if needed (macOS)
podman machine start

# Solution 3: Fall back to Docker
unset KIND_EXPERIMENTAL_PROVIDER
kind create cluster --config deploy/kubernetes/kind-config.yaml
```

### Issue: Docker Permission Denied
**Symptoms**:
```
permission denied while trying to connect to Docker daemon socket
```

**Solutions**:
```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
newgrp docker

# Start Docker service (macOS)
open -a Docker

# Alternative: Use sudo (not recommended)
sudo kind create cluster --config deploy/kubernetes/kind-config.yaml
```

## ⚙️ Kubernetes Operator Issues

### Issue: Operator Pod CrashLoopBackOff
**Symptoms**:
```bash
kubectl get pods -n toolhive-system
# NAME                                READY   STATUS             RESTARTS
# toolhive-operator-xxx               0/1     CrashLoopBackOff   5
```

**Diagnosis**:
```bash
# Check operator logs
kubectl logs -n toolhive-system -l app.kubernetes.io/name=toolhive-operator

# Check events
kubectl get events -n toolhive-system --sort-by=.metadata.creationTimestamp

# Verify CRDs installation
kubectl get crd | grep toolhive
```

**Solutions**:
```bash
# Solution 1: Reinstall CRDs first
helm uninstall toolhive-operator -n toolhive-system
helm uninstall toolhive-operator-crds
helm upgrade -i toolhive-operator-crds oci://ghcr.io/stacklok/toolhive/toolhive-operator-crds
helm upgrade -i toolhive-operator oci://ghcr.io/stacklok/toolhive/toolhive-operator -n toolhive-system --create-namespace

# Solution 2: Check resource constraints
kubectl describe pod -n toolhive-system -l app.kubernetes.io/name=toolhive-operator

# Solution 3: Verify cluster resources
kubectl top nodes
kubectl get nodes
```

### Issue: CRDs Not Installing
**Symptoms**:
```
Error: failed to install CRD: connection refused
```

**Diagnosis**:
```bash
# Check cluster connectivity
kubectl cluster-info
kubectl get nodes

# Verify Helm configuration
helm version
helm list -A
```

**Solutions**:
```bash
# Solution 1: Verify cluster access
kubectl config current-context
kubectl config get-contexts

# Solution 2: Switch to correct context
kubectl config use-context kind-toolhive-cluster

# Solution 3: Recreate cluster if needed
kind delete cluster --name toolhive-cluster
kind create cluster --config deploy/kubernetes/kind-config.yaml
```

## 📋 Registry Configuration Issues

### Issue: Registry Schema Validation Fails
**Symptoms**:
```json
{"message": "Additional properties are not allowed"}
```

**Diagnosis**:
```bash
# Validate JSON syntax
python3 -m json.tool registry/registry.json

# Check against schema
jsonschema schema.json -i registry.json
```

**Solutions**:
```bash
# Solution 1: Fix permissions structure
# WRONG:
"permissions": {"network": true}

# CORRECT:
"permissions": {
  "network": {
    "outbound": {
      "insecure_allow_all": true
    }
  }
}

# Solution 2: Add required metadata
"metadata": {
  "stars": 0,
  "pulls": 0,
  "last_updated": "2025-09-23T20:00:00Z"
}

# Solution 3: Validate against official examples
curl -s https://raw.githubusercontent.com/stacklok/toolhive/main/pkg/registry/data/registry.json > official-registry.json
# Compare structure with official registry
```

### Issue: ToolHive CLI Cannot Load Registry
**Symptoms**:
```
Error: failed to load registry: file not found
```

**Diagnosis**:
```bash
# Check registry configuration
thv config get-registry

# Verify file exists and permissions
ls -la registry.json
cat registry.json | head -5
```

**Solutions**:
```bash
# Solution 1: Use relative path
thv config set-registry registry/registry.json

# Solution 2: Verify file permissions
chmod 644 registry.json

# Solution 3: Test registry syntax
thv config set-registry registry/registry.json
thv registry list
```

## 🚀 MCP Server Deployment Issues

### Issue: Server Container Won't Start
**Symptoms**:
```bash
thv ls
# NAME          STATUS    
# osv-scanner   failed    
```

**Diagnosis**:
```bash
# Check container logs
podman logs osv-scanner

# Check ToolHive logs
ls ~/Library/Application\ Support/toolhive/logs/
tail -f ~/Library/Application\ Support/toolhive/logs/osv-scanner.log

# Test image manually
podman run --rm ghcr.io/stackloklabs/osv-mcp/server --help
```

**Solutions**:
```bash
# Solution 1: Pull image manually
podman pull ghcr.io/stackloklabs/osv-mcp/server

# Solution 2: Check network connectivity
curl -I https://ghcr.io

# Solution 3: Use different transport
thv run osv-scanner --transport=stdio

# Solution 4: Debug with verbose logging
thv --debug run osv-scanner
```

### Issue: Health Endpoint Not Responding
**Symptoms**:
```bash
curl http://localhost:21519/health
# curl: (7) Failed to connect to localhost port 21519: Connection refused
```

**Diagnosis**:
```bash
# Check running workloads
thv ls

# Verify port binding
netstat -tlnp | grep 21519
# or
lsof -i :21519

# Check container status
podman ps -a
```

**Solutions**:
```bash
# Solution 1: Wait for startup (may take 30+ seconds)
sleep 30 && curl http://localhost:21519/health

# Solution 2: Check correct port from thv ls
thv ls
# Use the actual assigned port

# Solution 3: Try different endpoint
curl http://localhost:PORT/mcp  # for streamable-http
curl http://localhost:PORT/sse  # for stdio transport

# Solution 4: Restart workload
thv stop osv-scanner
thv run osv-scanner
```

## 🔐 Secret Management Issues

### Issue: Environment File Not Loading
**Symptoms**:
```
Error: failed to load env file: permission denied
```

**Diagnosis**:
```bash
# Check file existence and permissions
ls -la .secrets/gofetch-secrets.env

# Verify file format
cat .secrets/gofetch-secrets.env
```

**Solutions**:
```bash
# Solution 1: Fix file permissions
chmod 600 .secrets/gofetch-secrets.env

# Solution 2: Verify file format
# CORRECT format:
API_KEY=value
USER_AGENT=value

# NOT this:
export API_KEY=value

# Solution 3: Use relative path
thv run gofetch --env-file registry/.secrets/gofetch-secrets.env
```

### Issue: Secrets Not Applied
**Symptoms**: Environment variables not visible in container

**Diagnosis**:
```bash
# Check if secrets are loaded (will be hidden in output)
thv --debug run gofetch --env-file .secrets/gofetch-secrets.env

# Check container environment (limited)
podman exec gofetch env | grep -E "(API_KEY|USER_AGENT)"
```

**Solutions**:
```bash
# Solution 1: Use individual env vars for testing
thv run gofetch -e API_KEY=test-value -e LOG_LEVEL=debug

# Solution 2: Verify secret file content
echo "API_KEY=test123" > .secrets/test.env
thv run gofetch --env-file .secrets/test.env --name=test-gofetch

# Solution 3: Check registry env_vars configuration
# Ensure registry.json has correct env_vars definitions
```

## 🌐 Network Connectivity Issues

### Issue: MCP Server Cannot Access External APIs
**Symptoms**: Server starts but cannot fetch external data

**Diagnosis**:
```bash
# Check container network configuration
podman inspect osv-scanner | grep -A5 -B5 Networks

# Test network from host
curl -I https://api.osv.dev

# Check permission profile
grep -A10 "permissions" registry.json
```

**Solutions**:
```bash
# Solution 1: Verify permission profile
# In registry.json:
"permissions": {
  "network": {
    "outbound": {
      "insecure_allow_all": true
    }
  }
}

# Solution 2: Test with different network configuration
thv run osv-scanner --permission-profile=network

# Solution 3: Check firewall/proxy settings
# Verify no corporate firewall blocking container traffic
```

## 📊 Monitoring and Logging Issues

### Issue: No Logs Generated
**Symptoms**: Log files empty or not created

**Diagnosis**:
```bash
# Check log directory
ls -la ~/Library/Application\ Support/toolhive/logs/

# Verify workload is running
thv ls

# Check log permissions
ls -la ~/Library/Application\ Support/toolhive/
```

**Solutions**:
```bash
# Solution 1: Create log directory manually
mkdir -p ~/Library/Application\ Support/toolhive/logs

# Solution 2: Run with explicit logging
thv run osv-scanner --foreground  # Shows logs directly

# Solution 3: Check container logs directly
podman logs osv-scanner

# Solution 4: Enable debug logging
thv --debug run osv-scanner
```

### Issue: OpenTelemetry Not Working
**Symptoms**: No traces/metrics despite configuration

**Diagnosis**:
```bash
# Check OTEL configuration
thv run gofetch --otel-tracing-enabled --otel-service-name=test --name=otel-test

# Verify OTEL endpoint if specified
curl -I https://api.honeycomb.io  # or your endpoint
```

**Solutions**:
```bash
# Solution 1: Start with basic OTEL
thv run gofetch \
  --otel-tracing-enabled \
  --otel-service-name=gofetch-test \
  --otel-sampling-rate=1.0

# Solution 2: Check OTEL endpoint configuration
# For Honeycomb:
thv run gofetch \
  --otel-endpoint=https://api.honeycomb.io \
  --otel-headers="x-honeycomb-team=YOUR-API-KEY" \
  --otel-tracing-enabled

# Solution 3: Enable metrics endpoint
thv run gofetch --otel-enable-prometheus-metrics-path
curl http://localhost:PORT/metrics
```

## 🔧 CLI Tool Issues

### Issue: ToolHive CLI Not Found
**Symptoms**:
```bash
thv version
# command not found: thv
```

**Solutions**:
```bash
# Solution 1: Add to PATH
export PATH="$HOME/bin:$PATH"
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc  # or ~/.bashrc

# Solution 2: Use full path
~/bin/thv version

# Solution 3: Install to system location (with sudo)
sudo cp thv /usr/local/bin/

# Solution 4: Create symlink
ln -s ./thv ~/bin/thv
```

### Issue: CLI Commands Hang or Timeout
**Symptoms**: Commands never complete or timeout

**Diagnosis**:
```bash
# Check if container runtime is responding
podman ps
# or
docker ps

# Test basic container operations
podman run --rm hello-world
```

**Solutions**:
```bash
# Solution 1: Restart container runtime
# For Podman:
podman machine restart

# For Docker:
# Restart Docker Desktop

# Solution 2: Use shorter timeout
thv run osv-scanner --timeout=30s

# Solution 3: Run in foreground to see errors
thv run osv-scanner --foreground
```

## 📚 Diagnostic Commands Reference

### System Health Check
```bash
# Container runtime
podman version && echo "Podman OK" || echo "Podman failed"
docker version && echo "Docker OK" || echo "Docker failed"

# Kubernetes cluster
kubectl cluster-info
kubectl get nodes
kubectl get pods -A | grep -E "(FAILED|ERROR|CrashLoop)"

# ToolHive operator
kubectl get pods -n toolhive-system
kubectl logs -n toolhive-system -l app.kubernetes.io/name=toolhive-operator --tail=10

# ToolHive CLI
thv version
thv ls
thv config get-registry
```

### Network Connectivity Test
```bash
# External connectivity
curl -I https://github.com
curl -I https://ghcr.io

# Internal connectivity
kubectl run test-pod --image=busybox --rm -it -- nslookup kubernetes.default

# Container registry access
podman pull hello-world
```

### Registry Validation
```bash
# JSON syntax
python3 -m json.tool registry/registry.json > /dev/null && echo "JSON OK"

# Schema validation
jsonschema schema.json -i registry.json

# ToolHive registry loading
thv config set-registry registry/registry.json
thv registry list
```

## 🆘 Emergency Recovery Procedures

### Complete Environment Reset
```bash
# Stop all ToolHive workloads
thv ls | tail -n +2 | awk '{print $1}' | xargs -I {} thv stop {}

# Remove all containers
podman rm -f $(podman ps -aq)

# Reset ToolHive configuration
rm -rf ~/.config/toolhive
rm -rf ~/Library/Application\ Support/toolhive

# Recreate kind cluster
kind delete cluster --name toolhive-cluster
kind create cluster --config deploy/kubernetes/kind-config.yaml

# Reinstall operator
helm uninstall toolhive-operator -n toolhive-system
helm uninstall toolhive-operator-crds
# Then follow installation steps
```

### Backup Important Configurations
```bash
# Backup registry
cp registry.json registry.json.backup

# Backup ToolHive config
cp -r ~/.config/toolhive ~/.config/toolhive.backup

# Backup secrets
tar -czf secrets-backup.tar.gz .secrets/

# Export kind cluster config
kind export kubeconfig --name toolhive-cluster --kubeconfig=cluster-backup.yaml
```

## 📞 Getting Additional Help

### Official Resources
- [Toolhive Documentation](https://docs.stacklok.com/toolhive/)
- [GitHub Issues](https://github.com/stacklok/toolhive/issues)
- [Stacklok Discord](https://discord.gg/stacklok)

### Debug Information to Collect
When reporting issues, include:
```bash
# System information
uname -a
podman version  # or docker version
kubectl version --client
thv version

# Configuration
thv config get-registry
kubectl get pods -A
thv ls

# Recent logs
kubectl logs -n toolhive-system -l app.kubernetes.io/name=toolhive-operator --tail=50
```

### Log Collection Script
```bash
#!/bin/bash
# collect-debug-info.sh
mkdir -p debug-info
thv version > debug-info/thv-version.txt
kubectl cluster-info > debug-info/cluster-info.txt
kubectl get pods -A > debug-info/all-pods.txt
kubectl logs -n toolhive-system -l app.kubernetes.io/name=toolhive-operator > debug-info/operator-logs.txt
thv ls > debug-info/workloads.txt
cp registry.json debug-info/
tar -czf debug-info-$(date +%Y%m%d-%H%M%S).tar.gz debug-info/
```

This troubleshooting guide covers the most common issues encountered during setup and operation. For issues not covered here, refer to the official documentation or community support channels.