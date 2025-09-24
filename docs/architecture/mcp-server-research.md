# MCP Server Deployment Research Results

## Available MCP Server Images

Based on documentation and examples, the following MCP server images are available for testing:

### 1. **OSV MCP Server** (Recommended for Testing)
- **Image**: `ghcr.io/stackloklabs/osv-mcp/server`
- **Purpose**: Open Source Vulnerability database integration
- **Transport**: `streamable-http`
- **Port**: 8080
- **Permission Profile**: `network`

### 2. **GoFetch MCP Server** (Web Content Fetching)
- **Image**: `ghcr.io/stackloklabs/gofetch/server:latest`
- **Purpose**: Web content fetching and processing
- **Transport**: `stdio` (default)
- **Port**: 8080
- **Permission Profile**: `network`

### 3. **Other Stacklok Labs Images**
Common pattern: `ghcr.io/stackloklabs/<tool>/server`
- Check GitHub Container Registry for additional available images

## MCPServer CRD Structure

### Required Fields
- `image`: Container image for the MCP server
- `permissionProfile.type`: "builtin" or "configmap"
- `permissionProfile.name`: "none" or "network" (for builtin)

### Transport Options
1. **`stdio`** (Default)
   - Standard input/output communication
   - Requires `proxyMode`: "sse" or "streamable-http"
   
2. **`streamable-http`**
   - HTTP-based communication
   - More suitable for web-based clients
   
3. **`sse`** (Server-Sent Events)
   - Real-time communication
   - Good for streaming data

### Permission Profiles
1. **`builtin` Type**:
   - `none`: No network access
   - `network`: Network access allowed
   
2. **`configmap` Type**:
   - Custom permission profiles via ConfigMap
   - Requires ConfigMap name and key

### Common Configuration Fields
- `port`: Exposed service port (optional)
- `targetPort`: Container port (optional)
- `env`: Environment variables
- `args`: Additional command arguments
- `resources`: Resource limits/requests
- `volumes`: Volume mounts
- `secrets`: Secret references
- `serviceAccount`: Custom service account

### Advanced Features
- **OIDC Authentication**: Enterprise auth integration
- **Authorization Config**: Cedar-based policy engine
- **Audit Logging**: Security audit trails
- **Telemetry**: Observability configuration
- **Tool Filtering**: Restrict available tools via MCPToolConfig

## Example Deployment Templates

### Basic OSV Server
```yaml
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPServer
metadata:
  name: osv-server
  namespace: default
spec:
  image: ghcr.io/stackloklabs/osv-mcp/server
  transport: streamable-http
  targetPort: 8080
  port: 8080
  permissionProfile:
    type: builtin
    name: network
```

### GoFetch with Custom Environment
```yaml
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPServer
metadata:
  name: gofetch-server
  namespace: default
spec:
  image: ghcr.io/stackloklabs/gofetch/server:latest
  transport: stdio
  proxyMode: sse
  permissionProfile:
    type: builtin
    name: network
  env:
  - name: GOFETCH_PORT
    value: "8080"
  - name: LOG_LEVEL
    value: "info"
```

### Production-Ready with Resources
```yaml
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPServer
metadata:
  name: production-mcp
  namespace: default
spec:
  image: ghcr.io/stackloklabs/osv-mcp/server
  transport: streamable-http
  targetPort: 8080
  port: 8080
  permissionProfile:
    type: builtin
    name: network
  resources:
    limits:
      cpu: 500m
      memory: 512Mi
    requests:
      cpu: 100m
      memory: 128Mi
  telemetry:
    enabled: true
  audit:
    enabled: true
```

## Deployment Process
1. Operator detects MCPServer resource creation
2. Creates RBAC resources (ServiceAccount, Role, RoleBinding)
3. Generates proxy pod and service
4. Launches MCP server container
5. Updates MCPServer status with URL and phase

## Monitoring and Verification
```bash
# Check MCPServer status
kubectl get mcpservers

# Detailed information
kubectl describe mcpserver <NAME>

# Check created resources
kubectl get pods,services -l mcpserver=<NAME>

# Check operator logs
kubectl logs -n toolhive-system -l app.kubernetes.io/name=toolhive-operator
```

## Security Considerations
- Permission profiles limit network access
- RBAC automatically configured per server
- Secret injection supported for sensitive data
- OIDC authentication available for enterprise use
- Audit logging for compliance requirements

## Ready for Task 7: Deploy Test MCP Server
Recommended first deployment: **OSV MCP Server** with `streamable-http` transport for easier testing and validation.