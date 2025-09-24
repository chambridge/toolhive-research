# MCP Server Deployment Guide

## Overview

This guide provides comprehensive information for deploying MCP servers using the ToolHive operator, including server configurations, CRD specifications, and deployment patterns for catalog integration.

## Available MCP Servers

### OSV Vulnerability Scanner

**Purpose**: Security vulnerability scanning and analysis using the Open Source Vulnerability database.

#### Server Configuration
- **Server ID**: `osv-scanner`
- **Container Image**: `ghcr.io/stackloklabs/osv-mcp/server`
- **Transport**: `streamable-http`
- **Target Port**: 8080
- **Status**: Active
- **Tier**: Community

#### Tool Capabilities
1. **`vulnerability-scan`**: Scans software projects for known vulnerabilities
2. **`security-analysis`**: Provides detailed security analysis reports
3. **`osv-query`**: Queries the OSV database for specific vulnerability information

#### Network & Security Requirements
- **Network Access**: Full outbound internet access (for OSV database APIs)
- **Permission Profile**: `network`
- **Filesystem Access**: None (read-only container)

#### Environment Variables
- **`LOG_LEVEL`** (optional): Controls logging verbosity (debug, info, warn, error)
- **`PORT`** (optional): Override default listening port (default: 8080)

### GoFetch Web Content Fetcher

**Purpose**: Web content fetching and HTTP request handling for automation and data retrieval.

#### Server Configuration
- **Server ID**: `gofetch`
- **Container Image**: `ghcr.io/stackloklabs/gofetch/server:latest`
- **Transport**: `stdio` (with proxy)
- **Status**: Active
- **Tier**: Community

#### Tool Capabilities
1. **`web-fetch`**: Retrieves web page content and resources
2. **`http-request`**: Performs HTTP requests with custom headers and methods
3. **`url-get`**: Simple URL content retrieval

#### Network & Security Requirements
- **Network Access**: Full outbound internet access (for web resources)
- **Permission Profile**: `network`
- **Filesystem Access**: None (read-only container)

#### Environment Variables
- **`GOFETCH_PORT`** (optional): Port for internal server communication
- **`LOG_LEVEL`** (optional): Controls logging verbosity
- **`USER_AGENT`** (optional): Custom User-Agent header for HTTP requests
- **`MAX_RETRIES`** (optional): Maximum number of retries for failed requests
- **`API_KEY`** (optional, secret): API key for authenticated requests

## MCPServer CRD Specification

### Required Fields
- **`image`**: Container image for the MCP server
- **`permissionProfile.type`**: "builtin" or "configmap"
- **`permissionProfile.name`**: "none" or "network" (for builtin)

### Transport Options

#### 1. `stdio` (Default)
- Standard input/output communication
- Requires `proxyMode`: "sse" or "streamable-http"
- Best for traditional CLI-style tools

#### 2. `streamable-http`
- HTTP-based communication
- More suitable for web-based clients
- Direct HTTP endpoint exposure

#### 3. `sse` (Server-Sent Events)
- Real-time communication
- Good for streaming data
- Event-driven updates

### Permission Profiles

#### Built-in Types
1. **`none`**: No network access, isolated container
2. **`network`**: Network access allowed, internet connectivity

#### Custom Types
- **`configmap`**: Custom permission profiles via ConfigMap
- Requires ConfigMap name and key specification
- Allows fine-grained security controls

### Configuration Fields

| Field | Description | Optional |
|-------|-------------|----------|
| `port` | Exposed service port | ✅ Yes |
| `targetPort` | Container port | ✅ Yes |
| `env` | Environment variables | ✅ Yes |
| `args` | Additional command arguments | ✅ Yes |
| `resources` | Resource limits/requests | ✅ Yes |
| `volumes` | Volume mounts | ✅ Yes |
| `secrets` | Secret references | ✅ Yes |
| `serviceAccount` | Custom service account | ✅ Yes |

### Advanced Features

- **OIDC Authentication**: Enterprise authentication integration
- **Authorization Config**: Cedar-based policy engine
- **Audit Logging**: Security audit trails and compliance
- **Telemetry**: Observability and monitoring configuration
- **Tool Filtering**: Restrict available tools via MCPToolConfig

## Deployment Examples

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
  - name: USER_AGENT
    value: "Enterprise-GoFetch/1.0"
```

### Production-Ready with Resources and Security
```yaml
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPServer
metadata:
  name: production-osv
  namespace: production
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
  env:
  - name: LOG_LEVEL
    value: "warn"
```

## Deployment Process

The ToolHive operator follows this workflow when deploying MCPServer resources:

1. **Resource Detection**: Operator detects MCPServer resource creation
2. **RBAC Setup**: Creates ServiceAccount, Role, and RoleBinding automatically
3. **Proxy Configuration**: Generates proxy pod and service for transport handling
4. **Container Launch**: Launches MCP server container with specified configuration
5. **Status Updates**: Updates MCPServer status with URL and deployment phase

## Monitoring and Verification

### Status Checking
```bash
# Check all MCPServer resources
kubectl get mcpservers -A

# Detailed information for specific server
kubectl describe mcpserver <NAME> -n <NAMESPACE>

# Check created resources
kubectl get pods,services -l mcpserver=<NAME> -n <NAMESPACE>
```

### Operator Logs
```bash
# Check operator logs for deployment issues
kubectl logs -n toolhive-system -l app.kubernetes.io/name=toolhive-operator

# Follow logs in real-time
kubectl logs -n toolhive-system -l app.kubernetes.io/name=toolhive-operator -f
```

### Service Connectivity
```bash
# Port-forward to test connectivity
kubectl port-forward svc/<mcpserver-name>-proxy 8080:8080 -n <NAMESPACE>

# Test HTTP endpoints (for streamable-http transport)
curl http://localhost:8080/health
```

## Security Considerations

### Permission Profile Guidelines
- **Development environments**: `network` profile for broad access
- **Production environments**: Custom ConfigMap profiles with restricted access
- **High-security environments**: `none` profile with explicit allowlists

### Network Security
- **Outbound restrictions**: Replace `insecure_allow_all` with specific host allowlists
- **Network policies**: Apply Kubernetes NetworkPolicies for additional isolation
- **Service mesh**: Consider Istio/Linkerd for advanced traffic controls

### Secrets Management
- **Environment variables**: Use Kubernetes Secrets for sensitive data
- **Volume mounts**: Mount secrets as files for complex configurations
- **RBAC**: Limit access to secrets via service account permissions

### Production Hardening
1. **Resource limits**: Always specify CPU and memory limits
2. **Security scanning**: Regularly scan container images for vulnerabilities
3. **Monitoring**: Enable telemetry and audit logging
4. **Updates**: Keep container images updated with latest security patches

## Container Image Information

### Image Registries
- **Primary registry**: GitHub Container Registry (ghcr.io)
- **Namespace**: stackloklabs
- **Architecture support**: Multi-arch (AMD64, ARM64)

### Available Images
- **OSV Scanner**: `ghcr.io/stackloklabs/osv-mcp/server:latest`
- **GoFetch**: `ghcr.io/stackloklabs/gofetch/server:latest`
- **Pattern**: `ghcr.io/stackloklabs/<tool>/server`

### Image Verification
For air-gapped environments, verify image digests:
```bash
# Get image digest
docker inspect ghcr.io/stackloklabs/osv-mcp/server:latest | jq '.[0].RepoDigests'

# Use digest in deployment
image: ghcr.io/stackloklabs/osv-mcp/server@sha256:abc123...
```

## Catalog Integration

### Registry Metadata Requirements
For catalog integration, each server should include:

- **Tool definitions**: Complete list of available tools with descriptions
- **Resource recommendations**: CPU/memory requirements for capacity planning
- **Security profiles**: Appropriate permission profiles for different environments
- **Environment variables**: Complete list with security classifications
- **Deployment metadata**: Verification status and testing information

### Tool Filtering
Use MCPToolConfig to restrict available tools:
```yaml
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPToolConfig
metadata:
  name: security-tools-only
  namespace: production
spec:
  toolsFilter:
    - "vulnerability-scan"
    - "security-analysis"
  toolsOverride:
    "vulnerability-scan":
      name: "enterprise-vuln-scan"
      description: "Enterprise vulnerability scanning with compliance reporting"
```

This guide provides the foundation for deploying and managing MCP servers in support of the catalog integration architecture.