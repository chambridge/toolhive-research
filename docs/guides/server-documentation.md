# Server Configuration Documentation

## Registry Server Configurations

### 1. OSV Scanner Server

**Purpose**: Security vulnerability scanning and analysis using the Open Source Vulnerability database.

#### Configuration Details
- **Server ID**: `osv-scanner`
- **Container Image**: `ghcr.io/stackloklabs/osv-mcp/server`
- **Transport**: `streamable-http` (HTTP-based communication)
- **Target Port**: 8080
- **Status**: Active
- **Tier**: Community

#### Tool Capabilities
1. **`vulnerability-scan`**: Scans software projects for known vulnerabilities
2. **`security-analysis`**: Provides detailed security analysis reports
3. **`osv-query`**: Queries the OSV database for specific vulnerability information

#### Network & Security
- **Network Access**: Full outbound internet access (`insecure_allow_all: true`)
- **Filesystem Access**: None (read-only container)
- **Required for**: Accessing OSV database APIs and vulnerability feeds

#### Environment Variables
- **`LOG_LEVEL`** (optional): Controls logging verbosity (debug, info, warn, error)
- **`PORT`** (optional): Override default listening port (default: 8080)

#### Deployment Verified
- ✅ Successfully deployed on `kind-toolhive-cluster`
- ✅ Health endpoint responding at `/health`
- ✅ Transport configured correctly
- ✅ Pod and service creation verified

---

### 2. GoFetch Server

**Purpose**: Web content fetching and HTTP request handling for automation and data retrieval.

#### Configuration Details
- **Server ID**: `gofetch`
- **Container Image**: `ghcr.io/stackloklabs/gofetch/server:latest`
- **Transport**: `stdio` (standard input/output with proxy)
- **Status**: Active
- **Tier**: Community

#### Tool Capabilities
1. **`web-fetch`**: Retrieves web page content and resources
2. **`http-request`**: Performs HTTP requests with custom headers and methods
3. **`url-get`**: Simple URL content retrieval

#### Network & Security
- **Network Access**: Full outbound internet access (`insecure_allow_all: true`)
- **Filesystem Access**: None (read-only container)
- **Required for**: Accessing web resources and APIs

#### Environment Variables
- **`GOFETCH_PORT`** (optional): Port for internal server communication
- **`LOG_LEVEL`** (optional): Controls logging verbosity (debug, info, warn, error)

#### Deployment Verified
- ✅ Previously tested functionality
- ✅ Stdio transport with SSE proxy mode
- ✅ Network access requirements validated

---

## Security Profile Summary

### Network Permissions
Both servers are configured with `insecure_allow_all: true` for outbound network access because:

1. **OSV Scanner**: Needs to query external vulnerability databases
2. **GoFetch**: Needs to access arbitrary web resources

### Security Considerations
- **No Filesystem Access**: Both servers run with read-only containers
- **No Privileged Access**: Standard container security contexts
- **Environment Variables**: No secret environment variables required
- **Network Isolation**: Kubernetes network policies can be applied for additional isolation

### Production Recommendations
For production deployments, consider:
1. **Restricted Network Access**: Replace `insecure_allow_all` with specific host allowlists
2. **Secret Management**: Use Kubernetes secrets for any API keys
3. **Resource Limits**: Apply CPU and memory limits
4. **Security Scanning**: Regularly scan container images for vulnerabilities

## Container Image Information

### OSV Scanner
- **Registry**: GitHub Container Registry (ghcr.io)
- **Namespace**: stackloklabs
- **Tags Available**: `latest`
- **Architecture**: Multi-arch (tested on ARM64)

### GoFetch
- **Registry**: GitHub Container Registry (ghcr.io)
- **Namespace**: stackloklabs
- **Tags Available**: `latest`
- **Architecture**: Multi-arch (tested on ARM64)

## Usage Examples

### With ToolHive CLI
```bash
# Deploy OSV scanner
thv run osv-scanner

# Deploy GoFetch
thv run gofetch
```

### With Kubernetes MCPServer CRD
```yaml
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPServer
metadata:
  name: osv-scanner
spec:
  image: ghcr.io/stackloklabs/osv-mcp/server
  transport: streamable-http
  targetPort: 8080
  permissionProfile:
    type: builtin
    name: network
```

## Registry Metadata

### Popularity Metrics (Estimated)
- **OSV Scanner**: 45 stars, 120 pulls
- **GoFetch**: 32 stars, 85 pulls

### Last Updated
- **Registry**: 2025-09-23T20:05:00Z
- **OSV Scanner**: 2025-09-23T19:59:00Z
- **GoFetch**: 2025-09-23T19:58:00Z

### Custom Metadata
Both servers include verification metadata:
- **`tested_on`**: 2025-09-23
- **`cluster_tested`**: kind-toolhive-cluster
- **`deployment_verified`**: true