# Catalog API Specification for MCP Registry Integration

## Overview

This document defines the API specification for the cluster-wide MCP Catalog service that enables customers to browse, select, and deploy MCP servers into namespace-scoped registries in air-gapped environments.

## API Endpoints

### 1. Server Discovery

#### GET `/api/v1/mcp_servers`
List all available MCP servers with filtering options.

**Query Parameters:**
- `category` - Filter by category (`validated`, `community`)
- `tags` - Comma-separated list of tags to filter by
- `tools` - Comma-separated list of required tools
- `search` - Free-text search across name/description

**Response:**
```json
{
  "servers": [
    {
      "name": "osv-scanner",
      "display_name": "OSV Vulnerability Scanner",
      "description": "Open Source Vulnerability scanner for security analysis",
      "category": "validated",
      "provider": "OSV",
      "image": "ghcr.io/stackloklabs/osv-mcp/server",
      "transport": "streamable-http",
      "target_port": 8080,
      "tools": [
        {
          "name": "vulnerability-scan",
          "description": "Scan for known vulnerabilities"
        },
        {
          "name": "security-analysis", 
          "description": "Perform security analysis"
        },
        {
          "name": "osv-query",
          "description": "Query OSV database directly"
        }
      ],
      "tags": ["security", "vulnerability", "scanning", "osv"],
      "metadata": {
        "stars": 45,
        "pulls": 120,
        "last_updated": "2025-09-23T19:59:00Z",
        "repository_url": "https://github.com/stackloklabs/osv-mcp"
      },
      "deployment_config": {
        "recommended_resources": {
          "cpu": "100m",
          "memory": "128Mi",
          "cpu_limit": "500m",
          "memory_limit": "512Mi"
        },
        "security_profile": "network",
        "env_vars": [
          {
            "name": "LOG_LEVEL",
            "description": "Logging level",
            "required": false,
            "default": "info"
          }
        ]
      }
    }
  ],
  "metadata": {
    "total_count": 25,
    "filtered_count": 1,
    "categories": {
      "validated": 12,
      "community": 13
    }
  }
}
```

#### GET `/api/v1/servers/{server_name}`
Get detailed information about a specific server.

### 2. Server Metadata Export

#### GET `/api/v1/mcp_servers/{server_name}/export`
Export complete metadata for a specific server to support MCPRegistry creation.

**Response:**
```json
{
  "metadata": {
    "namespace": "production",
    "registry_name": "customer-registry",
    "display_name": "Production MCP Registry"
  },
  "configuration": {
    "enforce_servers": true,
    "enforce_tools": true,
    "auto_sync": false
  },
  "servers": [
    {
      "name": "osv-scanner",
      "configuration": {
        "custom_image": "internal-registry.company.com/osv-mcp/server:v1.0.0",
        "custom_image_digest": "sha256:abcd1234...",
        "tools_filter": ["vulnerability-scan", "security-analysis"],
        "tool_overrides": {
          "vulnerability-scan": {
            "name": "enterprise-vuln-scan",
            "description": "Enterprise vulnerability scanning"
          }
        },
        "env_overrides": {
          "LOG_LEVEL": "warn"
        },
        "resources": {
          "cpu": "200m",
          "memory": "256Mi",
          "cpu_limit": "1000m",
          "memory_limit": "1Gi"
        }
      }
    }
  ],
  "filters": {
    "global_tags": {
      "include": ["security"],
      "exclude": ["deprecated"]
    }
  }
}
```


### 3. Categories and Metadata

#### GET `/api/v1/categories`
List available categories and their metadata.

**Response:**
```json
{
  "categories": {
    "validated": {
      "display_name": "Validated MCP Servers",
      "description": "Production-ready servers that have been thoroughly tested and validated",
      "server_count": 12,
      "enforcement_recommended": true,
      "verification_criteria": [
        "Security audit completed",
        "Performance benchmarks passed",
        "Documentation complete",
        "Enterprise support available"
      ]
    },
    "community": {
      "display_name": "Community MCP Servers",
      "description": "Community-contributed servers with varying levels of maturity",
      "server_count": 13,
      "enforcement_recommended": false,
      "verification_criteria": [
        "Basic functionality verified",
        "Source code available",
        "Community maintained"
      ]
    }
  }
}
```

#### GET `/api/v1/tools`
List all available tools across all servers.

**Response:**
```json
{
  "tools": [
    {
      "name": "vulnerability-scan",
      "description": "Scan for known vulnerabilities in software",
      "category": "security",
      "servers": ["osv-scanner", "trivy-scanner"],
      "usage_count": 2
    },
    {
      "name": "web-fetch",
      "description": "Fetch content from web URLs",
      "category": "web",
      "servers": ["gofetch", "web-scraper"],
      "usage_count": 2
    }
  ],
  "categories": {
    "security": 8,
    "web": 5,
    "data": 3,
    "analysis": 4
  }
}
```

### 4. Registry Management

#### GET `/api/v1/registries/{namespace}`
Get information about deployed registries in a namespace.

#### POST `/api/v1/registries/{namespace}/sync`
Trigger manual sync for a registry.

#### GET `/api/v1/registries/{namespace}/status`
Get detailed status of registry deployment.

## Data Models

### Server Definition
```json
{
  "name": "string",
  "display_name": "string",
  "description": "string",
  "category": "validated|community",
  "tier": "Official|Community", 
  "status": "Active|Deprecated",
  "image": "string",
  "transport": "stdio|sse|streamable-http",
  "target_port": "integer",
  "tools": [
    {
      "name": "string",
      "description": "string"
    }
  ],
  "tags": ["string"],
  "metadata": {
    "stars": "integer",
    "pulls": "integer", 
    "last_updated": "date-time",
    "repository_url": "string"
  },
  "air_gapped": {
    "image_digest": "string",
    "offline_docs_path": "string",
    "dependencies": ["string"],
    "verified_date": "date-time",
    "size_mb": "integer"
  },
  "deployment_config": {
    "recommended_resources": {
      "cpu": "string",
      "memory": "string",
      "cpu_limit": "string", 
      "memory_limit": "string"
    },
    "security_profile": "none|network|custom",
    "env_vars": [
      {
        "name": "string",
        "description": "string",
        "required": "boolean",
        "default": "string",
        "secret": "boolean"
      }
    ]
  }
}
```

### Registry Generation Request
```json
{
  "metadata": {
    "namespace": "string",
    "registry_name": "string",
    "display_name": "string"
  },
  "configuration": {
    "enforce_servers": "boolean",
    "enforce_tools": "boolean", 
    "auto_sync": "boolean"
  },
  "servers": [
    {
      "name": "string",
      "configuration": {
        "custom_image": "string",
        "custom_image_digest": "string",
        "tools_filter": ["string"],
        "tool_overrides": {
          "tool_name": {
            "name": "string",
            "description": "string"
          }
        },
        "env_overrides": {
          "ENV_VAR": "string"
        },
        "resources": {
          "cpu": "string",
          "memory": "string",
          "cpu_limit": "string",
          "memory_limit": "string"
        }
      }
    }
  ],
  "filters": {
    "global_tags": {
      "include": ["string"],
      "exclude": ["string"]
    }
  }
}
```

## Error Handling

### Standard Error Response
```json
{
  "error": {
    "code": "INVALID_REQUEST|SERVER_NOT_FOUND|NAMESPACE_ACCESS_DENIED",
    "message": "Human readable error message",
    "details": {
      "field": "specific field that caused error",
      "value": "invalid value provided"
    }
  }
}
```

### HTTP Status Codes
- `200` - Success
- `400` - Bad Request (invalid parameters)
- `403` - Forbidden (namespace access denied)
- `404` - Not Found (server/resource not found)
- `409` - Conflict (registry already exists)
- `500` - Internal Server Error

## Authentication & Authorization

### RBAC Integration
The catalog API should integrate with Kubernetes RBAC to ensure users can only generate registries for namespaces they have access to.

**Required Permissions:**
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: catalog-api-user
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["create", "get", "list", "update"]
- apiGroups: ["toolhive.stacklok.dev"]
  resources: ["mcpregistries", "mcptoolconfigs"]
  verbs: ["create", "get", "list", "update"]
```

### Namespace Access Control
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["create", "get", "list", "update"]
```

This API specification provides a comprehensive interface for customers to discover, select, and deploy MCP servers in air-gapped environments while maintaining security and proper access controls.