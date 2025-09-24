# Custom MCP Registry Structure Plan

## Registry Overview
**Purpose**: Create a custom Toolhive MCP registry for testing and demonstration
**Target**: Include tested MCP servers with proper configuration
**Schema**: Based on Stacklok's official schema from GitHub

## Registry Structure

### Top-Level Required Fields
1. **`last_updated`**: RFC3339 timestamp (auto-generated)
2. **`version`**: Semantic version (start with "1.0.0")
3. **`servers`**: Object containing server entries

### Planned Server Entries

#### 1. **OSV Vulnerability Scanner** (Primary)
- **Key**: `osv-scanner`
- **Image**: `ghcr.io/stackloklabs/osv-mcp/server`
- **Status**: `Active`
- **Tier**: `Community`
- **Transport**: `streamable-http`
- **Target Port**: 8080
- **Permission Profile**: Network access required
- **Tools**: Vulnerability scanning, security analysis
- **Tested**: ✅ Successfully deployed in our cluster

#### 2. **GoFetch Web Scraper** (Secondary)
- **Key**: `gofetch`
- **Image**: `ghcr.io/stackloklabs/gofetch/server:latest`
- **Status**: `Active`
- **Tier**: `Community`
- **Transport**: `stdio` with SSE proxy
- **Permission Profile**: Network access required
- **Tools**: Web content fetching, HTTP requests
- **Tested**: ✅ Previously validated functionality

#### 3. **Custom Test Server** (Future)
- **Key**: `test-server`
- **Placeholder**: For future custom MCP server development
- **Status**: `Deprecated` (not yet implemented)

### Server Configuration Standards

#### Required Properties
- `description`: Clear, concise server purpose
- `image`: Full container image path with tag
- `status`: "Active" for working servers
- `tier`: "Community" (vs "Official")
- `tools`: Array of provided tool capabilities
- `transport`: Communication method

#### Network & Security
- `permissions.network`: `true` for servers needing internet access
- `permissions.filesystem`: `false` (default, no file access)
- `target_port`: Container listening port
- `environment`: Required environment variables

#### Metadata & Discovery
- `repository`: Link to source code
- `tags`: Searchable keywords
- `categories`: Functional grouping
- `documentation`: Usage instructions

## Registry File Structure
```
custom-mcp-registry/
├── schema.json          # Downloaded schema for validation
├── registry.json        # Main registry file
├── registry-plan.md     # This planning document
├── examples/            # Example configurations
│   ├── osv-example.yaml
│   └── gofetch-example.yaml
└── README.md           # Registry documentation
```

## Validation Strategy
1. **Schema Validation**: Ensure JSON matches official schema
2. **Image Availability**: Verify all container images exist and are accessible
3. **Functionality Testing**: Deploy each server to validate configuration
4. **Documentation**: Include clear usage examples

## Registry Hosting Options
1. **Local File**: For development and testing
2. **Git Repository**: Version controlled, easily shareable
3. **HTTP Server**: For broader distribution
4. **Container Registry**: Package with container images

## Example Registry Structure
```json
{
  "$schema": "https://raw.githubusercontent.com/stacklok/toolhive/main/pkg/registry/data/schema.json",
  "version": "1.0.0",
  "last_updated": "2025-09-23T20:00:00Z",
  "servers": {
    "osv-scanner": {
      "description": "Open Source Vulnerability scanner for security analysis",
      "image": "ghcr.io/stackloklabs/osv-mcp/server",
      "status": "Active",
      "tier": "Community",
      "transport": "streamable-http",
      "target_port": 8080,
      "tools": ["vulnerability-scan", "security-analysis"],
      "permissions": {
        "network": true,
        "filesystem": false
      }
    }
  }
}
```

## Next Steps
1. Create base registry.json with OSV server
2. Add tested GoFetch server configuration
3. Validate against schema
4. Test with ToolHive CLI
5. Document usage examples