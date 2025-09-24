# Advanced Configuration Examples

## Server Groups Implementation

The registry now includes organized server groups for better management:

### Security Tools Group
```json
{
  "name": "security-tools",
  "description": "Security analysis and vulnerability scanning tools for comprehensive security assessment",
  "servers": {
    "osv-scanner": { ... }
  }
}
```

### Web Tools Group  
```json
{
  "name": "web-tools", 
  "description": "Web content fetching and HTTP automation tools for data retrieval and web scraping tasks",
  "servers": {
    "gofetch": { ... }
  }
}
```

## Enhanced Environment Variables

### Standard Configuration Variables
- **LOG_LEVEL**: Controls logging verbosity (debug, info, warn, error)
- **PORT**: Override default listening ports
- **USER_AGENT**: Custom User-Agent headers for HTTP requests
- **MAX_RETRIES**: Retry configuration for failed requests

### Secret Management Variables
- **API_KEY**: Marked as `"secret": true` for secure handling
- Automatically excluded from logs and exported configurations

## Secret Management Setup

### Directory Structure
```
custom-mcp-registry/
├── .secrets/
│   └── gofetch-secrets.env
├── .gitignore              # Excludes secrets from git
└── registry.json
```

### Secret File Example (.secrets/gofetch-secrets.env)
```bash
API_KEY=demo-api-key-12345
USER_AGENT=ToolHive-Registry-Demo/1.0
MAX_RETRIES=3
```

### Usage with ToolHive CLI
```bash
# Run with secrets from file
thv run gofetch --env-file .secrets/gofetch-secrets.env

# Run with individual environment variables
thv run gofetch -e API_KEY=secret123 -e LOG_LEVEL=debug
```

## Monitoring and Logging Configuration

### OpenTelemetry Integration
```bash
# Run with distributed tracing enabled
thv run gofetch \
  --otel-tracing-enabled \
  --otel-service-name=gofetch-demo \
  --otel-sampling-rate=0.1

# Run with Prometheus metrics endpoint
thv run osv-scanner \
  --otel-enable-prometheus-metrics-path \
  --otel-metrics-enabled
```

### Log Management
- **Automatic Logging**: All workloads logged to `~/Library/Application Support/toolhive/logs/`
- **Log Files**: Named after workload (e.g., `gofetch-monitored.log`)
- **Structured Logging**: JSON format for easy parsing

### Current Running Workloads
```
NAME                PACKAGE                                      STATUS    URL                                            PORT
gofetch             ghcr.io/stackloklabs/gofetch/server:latest   running   http://127.0.0.1:60455/sse#gofetch             60455
gofetch-monitored   ghcr.io/stackloklabs/gofetch/server:latest   running   http://127.0.0.1:60890/sse#gofetch-monitored   60890
osv-scanner         ghcr.io/stackloklabs/osv-mcp/server:latest   running   http://127.0.0.1:21519/mcp                     21519
```

## Security Best Practices

### Secret Handling
1. **Never commit secrets**: `.gitignore` excludes all secret files
2. **File-based secrets**: Use `--env-file` for secure environment loading
3. **Secret marking**: Registry marks sensitive variables with `"secret": true`
4. **Rotation ready**: Easy to update secrets without registry changes

### Network Security
1. **Permission profiles**: Registry defines network access requirements
2. **Container isolation**: Each workload runs in isolated container
3. **Port management**: Dynamic port assignment prevents conflicts

### Registry Security
1. **Schema validation**: Full compliance with official Stacklok schema
2. **Image verification**: Warnings for unsigned images (configurable)
3. **Access control**: Local file permissions control registry access

## Production Deployment Recommendations

### Registry Hosting
```bash
# Local development
thv config set-registry /path/to/registry.json

# HTTP server deployment
thv config set-registry https://company.com/mcp-registry.json

# Git repository hosting
thv config set-registry https://raw.githubusercontent.com/company/mcp-registry/main/registry.json
```

### Monitoring Integration
```bash
# Honeycomb example
thv run server-name \
  --otel-endpoint=https://api.honeycomb.io \
  --otel-headers="x-honeycomb-team=your-api-key" \
  --otel-tracing-enabled

# Prometheus + Grafana
thv run server-name \
  --otel-enable-prometheus-metrics-path \
  --otel-metrics-enabled
```

### Secret Management Integration
```bash
# Kubernetes secrets
kubectl create secret generic mcp-secrets \
  --from-env-file=.secrets/gofetch-secrets.env

# HashiCorp Vault integration (via env files)
vault kv get -format=json secret/mcp/gofetch | \
  jq -r '.data.data | to_entries[] | "\(.key)=\(.value)"' > .secrets/vault-secrets.env
```

## Group-Based Deployment

### Deploy Entire Groups
```bash
# Deploy all security tools
thv run-group security-tools

# Deploy all web tools  
thv run-group web-tools
```

### Group Management
- **Logical Organization**: Related tools grouped together
- **Bulk Operations**: Deploy/stop entire groups
- **Dependency Management**: Define group-level dependencies
- **Resource Sharing**: Shared configurations across group members

## Registry Validation

### Schema Compliance
```bash
# Validate registry structure
jsonschema schema.json -i registry.json

# Test registry loading
thv config set-registry registry.json
thv registry list
```

### Advanced Validation
- **Image availability**: All container images pullable
- **Environment variables**: Required variables documented
- **Network permissions**: Appropriate access levels defined
- **Tool capabilities**: Accurate tool listings