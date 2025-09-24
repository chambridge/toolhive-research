# Toolhive Operator Installation Notes

## Prerequisites Verified ✅
- Kubernetes cluster: `toolhive-cluster` (v1.33.1) - ✅
- kubectl configured: `kind-toolhive-cluster` context - ✅  
- Helm: v3.17.0 (meets v3.14+ requirement) - ✅

## Helm Repository Information
- **Repository Type**: OCI Registry (not traditional Helm repo)
- **CRDs Chart**: `oci://ghcr.io/stacklok/toolhive/toolhive-operator-crds`
- **Operator Chart**: `oci://ghcr.io/stacklok/toolhive/toolhive-operator`

## Installation Commands

### Step 1: Install CRDs
```bash
helm upgrade -i toolhive-operator-crds oci://ghcr.io/stacklok/toolhive/toolhive-operator-crds
```

### Step 2: Install Operator
```bash
helm upgrade -i toolhive-operator oci://ghcr.io/stacklok/toolhive/toolhive-operator -n toolhive-system --create-namespace
```

## Configuration Options

### Deployment Modes
1. **Cluster Mode (Default)**: Cluster-wide access to manage MCPServer resources
   - Recommended for multi-namespace deployments
   - Full cluster RBAC permissions
   
2. **Namespace Mode**: Restricted access to specific namespaces
   - More secure for single-namespace deployments
   - Limited RBAC scope

### Custom Values (values.yaml)
```yaml
# Replica count for operator
replicaCount: 1

# ToolHive runner image configuration
runner:
  image:
    repository: ghcr.io/stacklok/toolhive/runner
    tag: latest
    pullPolicy: IfNotPresent

# Deployment mode: cluster or namespace
deploymentMode: cluster

# Resource limits and requests
resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

## Verification Commands
```bash
# Check operator pod status
kubectl get pods -n toolhive-system

# Check operator logs
kubectl logs -n toolhive-system -l app.kubernetes.io/name=toolhive-operator

# Verify CRDs installation
kubectl get crd | grep toolhive

# Check operator deployment
kubectl get deployment -n toolhive-system
```

## Management Commands

### Upgrade
```bash
helm upgrade toolhive-operator oci://ghcr.io/stacklok/toolhive/toolhive-operator -n toolhive-system --reuse-values
```

### Uninstall (if needed)
```bash
helm uninstall toolhive-operator -n toolhive-system
helm uninstall toolhive-operator-crds
```

## Key Considerations
- Uses OCI registry instead of traditional Helm repository
- CRDs must be installed separately before operator
- Supports easy migration between deployment modes
- Requires proper RBAC configurations
- Experimental feature - expect potential breaking changes

## Security Notes
- Operator runs in `toolhive-system` namespace
- Cluster mode requires cluster-wide RBAC permissions
- Consider namespace mode for enhanced security in production
- Monitor logs for any security warnings or issues