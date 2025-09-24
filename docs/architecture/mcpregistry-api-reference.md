# MCPRegistry API Reference

## Overview

This document provides a comprehensive reference for the MCPRegistry Custom Resource Definition (CRD) and its associated API operations in the ToolHive operator. MCPRegistry resources are namespace-scoped and enable deployment of curated MCP server collections with automatic API service exposure.

## Custom Resource Definition

### MCPRegistry v1alpha1

**API Version:** `toolhive.stacklok.dev/v1alpha1`  
**Kind:** `MCPRegistry`  
**Scope:** Namespaced  

### Spec Fields

#### Source Configuration

```yaml
spec:
  source:
    type: configmap | git        # Source type (air-gapped: use configmap)
    format: toolhive | upstream  # Data format (default: toolhive)
    
    # ConfigMap source (recommended for air-gapped)
    configmap:
      name: string              # ConfigMap name (required)
      key: registry.json        # Key containing registry data (default: registry.json)
    
    # Git source (not available in air-gapped)
    git:
      repository: string        # Git repository URL
      path: registry.json       # Path to registry file (default: registry.json)
      branch: string           # Git branch (mutually exclusive with tag/commit)
      tag: string              # Git tag (mutually exclusive with branch/commit)
      commit: string           # Git commit SHA (mutually exclusive with branch/tag)
```

#### Registry Configuration

```yaml
spec:
  displayName: string           # Human-readable registry name
  enforceServers: boolean       # Enforce registry whitelist (default: false)
  
  # Content filtering
  filter:
    names:
      include: [string]         # Glob patterns to include
      exclude: [string]         # Glob patterns to exclude
    tags:
      include: [string]         # Tags to include
      exclude: [string]         # Tags to exclude
```

#### Synchronization Policy

```yaml
spec:
  syncPolicy:                   # Optional automatic sync configuration
    interval: string            # Sync interval (Go duration format: 1h, 30m, 24h)
```

### Status Fields

```yaml
status:
  phase: Pending | Ready | Failed | Syncing | Terminating
  message: string               # Additional phase information
  
  # Synchronization status
  syncStatus:
    phase: Idle | Syncing | Complete | Failed
    message: string
    serverCount: integer        # Number of servers in registry
    lastSyncTime: date-time     # Last successful sync timestamp
    lastAttempt: date-time      # Last sync attempt timestamp
    attemptCount: integer       # Failed attempts since last success
    lastSyncHash: string        # Hash of last synced data
  
  # API service status
  apiStatus:
    phase: NotStarted | Deploying | Ready | Unhealthy | Error
    message: string
    endpoint: string            # API service URL
    readySince: date-time       # When API became ready
  
  # Storage reference
  storageRef:
    type: configmap
    configMapRef:
      name: string              # Internal storage ConfigMap name
  
  # Manual sync tracking
  lastManualSyncTrigger: string # Last processed sync annotation value
  
  # Standard Kubernetes conditions
  conditions: []
```

## Registry Data Schema

### ToolHive Registry Format

```json
{
  "$schema": "https://raw.githubusercontent.com/stacklok/toolhive/main/pkg/registry/data/schema.json",
  "version": "1.0.0",
  "last_updated": "2025-09-24T20:00:00Z",
  
  "servers": {
    "server-name": {
      "description": "Server description (10-500 chars)",
      "image": "container/image:tag",
      "status": "Active | Deprecated",
      "tier": "Official | Community",
      "transport": "stdio | sse | streamable-http",
      "target_port": 8080,
      "tools": ["tool1", "tool2"],
      "tags": ["tag1", "tag2"],
      
      "permissions": {
        "network": {
          "outbound": {
            "allow_host": ["domain.com"],
            "allow_port": [80, 443],
            "insecure_allow_all": false
          }
        },
        "read": ["/path/to/read"],
        "write": ["/path/to/write"],
        "privileged": false
      },
      
      "env_vars": [
        {
          "name": "ENV_VAR_NAME",
          "description": "Environment variable description",
          "required": false,
          "secret": false,
          "default": "default_value"
        }
      ],
      
      "metadata": {
        "stars": 45,
        "pulls": 120,
        "last_updated": "2025-09-23T19:59:00Z"
      },
      
      "repository_url": "https://github.com/org/repo",
      "docker_tags": ["latest", "v1.0.0"],
      
      "custom_metadata": {
        "tested_on": "2025-09-23",
        "deployment_verified": true
      }
    }
  },
  
  "groups": [
    {
      "name": "group-name",
      "description": "Group description",
      "servers": {
        "server-in-group": { /* server definition */ }
      }
    }
  ]
}
```

## API Service Endpoints

When an MCPRegistry is deployed, it automatically creates an API service that exposes the registry data via HTTP endpoints.

### Service URL Format
```
http://mcp-{registry-name}-api.{namespace}.svc.cluster.local:8080
```

### Available Endpoints

#### GET `/api/v1/servers`
List all servers in the registry.

**Query Parameters:**
- `tier` - Filter by tier (Official, Community)
- `status` - Filter by status (Active, Deprecated)
- `tags` - Comma-separated list of tags
- `transport` - Filter by transport type

**Response:**
```json
{
  "servers": [
    {
      "name": "osv-scanner",
      "description": "Open Source Vulnerability scanner",
      "image": "ghcr.io/stackloklabs/osv-mcp/server",
      "status": "Active",
      "tier": "Community",
      "transport": "streamable-http",
      "tools": ["vulnerability-scan", "security-analysis"],
      "tags": ["security", "vulnerability"]
    }
  ],
  "metadata": {
    "total": 1,
    "registry_version": "1.0.0",
    "last_updated": "2025-09-24T20:00:00Z"
  }
}
```

#### GET `/api/v1/servers/{name}`
Get detailed information about a specific server.

#### GET `/api/v1/groups`
List all groups in the registry.

#### GET `/api/v1/groups/{name}`
Get servers in a specific group.

#### GET `/api/v1/tools`
List all available tools across all servers.

#### GET `/api/v1/health`
Registry API health check.

## Operational Examples

### Basic Registry Deployment

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: production-registry-data
  namespace: production
data:
  registry.json: |
    {
      "version": "1.0.0",
      "last_updated": "2025-09-24T20:00:00Z",
      "servers": {
        "osv-scanner": {
          "description": "OSV vulnerability scanner",
          "image": "internal-registry.company.com/osv-mcp/server:v1.0.0",
          "status": "Active",
          "tier": "Community",
          "transport": "streamable-http",
          "target_port": 8080,
          "tools": ["vulnerability-scan"]
        }
      }
    }
---
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPRegistry
metadata:
  name: production-registry
  namespace: production
spec:
  displayName: "Production MCP Registry"
  enforceServers: true
  source:
    type: configmap
    configmap:
      name: production-registry-data
      key: registry.json
```

### Filtered Registry

```yaml
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPRegistry
metadata:
  name: security-registry
  namespace: security-team
spec:
  displayName: "Security Tools Registry"
  enforceServers: true
  source:
    type: configmap
    configmap:
      name: master-registry-data
      key: registry.json
  filter:
    tags:
      include: ["security", "vulnerability"]
    names:
      exclude: ["*-experimental"]
```

### Auto-Sync Registry

```yaml
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPRegistry
metadata:
  name: auto-sync-registry
  namespace: development
spec:
  displayName: "Development Registry"
  enforceServers: false
  source:
    type: configmap
    configmap:
      name: dev-registry-data
      key: registry.json
  syncPolicy:
    interval: "1h"  # Sync every hour
```

## Manual Synchronization

Trigger manual sync using annotations:

```bash
kubectl annotate mcpregistry production-registry \
  toolhive.stacklok.dev/sync-trigger="$(date -u +%Y%m%d%H%M%S)" \
  -n production
```

## Monitoring and Troubleshooting

### Check Registry Status
```bash
kubectl get mcpregistry -n production
kubectl describe mcpregistry production-registry -n production
```

### Monitor API Service
```bash
kubectl get pods -l app=mcp-registry-api -n production
kubectl logs -l app=mcp-registry-api -n production
```

### Test API Endpoints
```bash
kubectl port-forward svc/mcp-production-registry-api 8080:8080 -n production
curl http://localhost:8080/api/v1/servers
```

### Common Issues

#### Registry Not Syncing
- Check ConfigMap exists and contains valid JSON
- Verify JSON schema compliance
- Check operator logs for sync errors

#### API Service Unhealthy
- Verify registry sync completed successfully
- Check pod logs for API service errors
- Ensure network policies allow inbound traffic

#### Enforcement Issues
- When `enforceServers: true`, MCPServers with images not in registry will be rejected
- Check MCPServer events for enforcement violations
- Verify server images match registry entries exactly

## Security Considerations

### Access Control
- MCPRegistry resources are namespace-scoped
- API services are only accessible within the cluster
- Use NetworkPolicies to restrict API access
- ConfigMap access controls registry data modification

### Best Practices
- Use `enforceServers: true` in production environments
- Regularly audit registry contents
- Monitor sync status and API health
- Use semantic versioning for registry updates
- Implement proper RBAC for ConfigMap access

This API reference provides the foundation for integrating MCPRegistry resources with the catalog system while maintaining security and operational control in air-gapped environments.