# ToolHive Operator Architecture Notes

## Key Architecture Clarifications

### Registry API Architecture

The ToolHive operator implements a **distributed registry pattern** rather than a centralized API:

- **No central registry API** - The operator doesn't provide a single cluster-wide registry API
- **Per-registry API services** - Each MCPRegistry CRD automatically deploys its own API service
- **Namespace-scoped** - Registry APIs are isolated within their respective namespaces
- **Automatic deployment** - ToolHive operator handles API service creation and lifecycle

### API Service Pattern

```yaml
# When you create an MCPRegistry
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPRegistry
metadata:
  name: production-registry
  namespace: production

# The operator automatically creates:
# - API Service: mcp-production-registry-api.production.svc.cluster.local:8080
# - Endpoints: /api/v1/servers, /api/v1/groups, /api/v1/tools, etc.
```

### User Workflow (No CLI Required)

1. **Catalog Discovery** - Users query catalog API for server metadata
2. **Manual Resource Creation** - Users manually create:
   - ConfigMap with registry data (from catalog metadata)
   - MCPRegistry pointing to ConfigMap
   - MCPToolConfig for tool filtering
3. **Operator Automation** - ToolHive operator automatically:
   - Validates registry data
   - Deploys API service
   - Updates status with endpoint URLs

### Catalog Integration Points

The catalog system provides **metadata only** - it does not generate Kubernetes resources:

- **Server discovery** - Browse validated/community servers
- **Metadata export** - Complete server specifications for ConfigMap creation
- **Tool information** - Tool lists and descriptions for MCPToolConfig
- **Security guidance** - Recommended permission profiles and resource limits

### RBAC and Security

Each MCPRegistry deployment includes automatic RBAC creation:
- ServiceAccounts for registry pods
- Roles for registry operations
- Network policies (if configured)
- Security contexts and permission profiles

This distributed approach provides strong namespace isolation while enabling flexible registry management without requiring centralized services or CLI tools.