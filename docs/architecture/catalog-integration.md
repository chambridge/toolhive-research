# Catalog Integration Architecture

## Overview

This document outlines the integration architecture between a cluster-wide MCP Catalog API and namespace-scoped MCP Registries for air-gapped environments. The design supports both validated and community MCP servers while enabling customers to selectively deploy servers from the catalog into their registries.

## Air-Gapped Architecture Constraints

### No Git Repository Access
- **Challenge**: Standard MCPRegistry source type `git` is unavailable
- **Solution**: Use `configmap` source type exclusively
- **Benefit**: All registry data stored within cluster, no external dependencies

### Container Image Considerations
- Images must be pre-pulled or available in private registry
- Registry metadata should include image digests for verification
- Support for custom image repositories per environment

## Catalog to Registry Data Flow

```
┌─────────────────────────────┐
│      Catalog API            │
│   (Cluster-wide Service)    │
│                             │
│ ┌─────────────────────────┐ │
│ │   Validated Servers     │ │
│ │   Community Servers     │ │
│ │   Tool Metadata         │ │
│ │   Category Mappings     │ │
│ └─────────────────────────┘ │
└─────────────┬───────────────┘
              │
              ▼ User queries metadata
┌─────────────────────────────┐
│   User Creates Resources    │
│                             │
│ ┌─────────────────────────┐ │
│ │     MCPRegistry         │ │
│ │   (ConfigMap source)    │ │
│ │   ↓ Auto-deploys        │ │
│ │   Registry API Service  │ │
│ └─────────────────────────┘ │
│ ┌─────────────────────────┐ │
│ │    MCPToolConfig        │ │
│ │   (Tool filtering)      │ │
│ └─────────────────────────┘ │
└─────────────────────────────┘
```

## Catalog API Metadata Requirements

The catalog must maintain the standard MCP Registry schema fields plus catalog-specific extensions for air-gapped deployments. Users query the catalog to obtain all metadata necessary to create MCPRegistry and MCPToolConfig resources manually.

### Core Server Data Requirements

#### Mandatory MCP Registry Fields

| Field | Description | Required for MCPRegistry |
|-------|-------------|-------------------------|
| `name` | Server identifier (key in servers object) | ✅ Yes - used as server reference |
| `description` | Human-readable server purpose (10-500 chars) | ✅ Yes - MCPRegistry validation |
| `image` | Container image reference | ✅ Yes - deployment requirement |
| `status` | Active or Deprecated | ✅ Yes - MCPRegistry validation |
| `tier` | Official or Community | ✅ Yes - MCPRegistry validation |
| `tools` | Array of tool names provided | ✅ Yes - MCPRegistry validation |
| `transport` | Communication protocol (stdio/sse/streamable-http) | ✅ Yes - MCPRegistry validation |

#### Catalog-Specific Extensions

| Field | Purpose | Usage in Resource Creation |
|-------|---------|---------------------------|
| `category` | validated or community classification | Used for filtering and namespace targeting |
| `image` | SHA256 digest for image verification | Added to image reference for security |
| `tags` | Searchable keywords | Used for registry filtering |
| `dependencies` | Required capabilities (e.g., network-access) | Maps to permission profiles |
| `deployment_options.security_profile` | none, network, or custom | Maps to MCPRegistry permissions |
| `deployment_options.default_tool_filter` | Recommended tool subset | Used to create MCPToolConfig |

#### Optional Enhancement Fields

| Field | Description | Benefit |
|-------|-------------|---------|
| `target_port` | Container listening port | Needed for SSE/HTTP transports |
| `env_vars` | Environment variable definitions | Customer configuration options |
| `permissions` | Network/filesystem requirements | Security profile generation |
| `metadata.repository_url` | Source code location | Documentation and transparency |

### Category Organization Requirements

The catalog needs category-level metadata to support customer selection workflows and proper enforcement policies.

#### Category Definitions

| Category | Enforcement Recommendation | Target Namespace Pattern |
|----------|---------------------------|---------------------------|
| `validated` | `enforceServers: true` | Production environments |
| `community` | `enforceServers: false` | Development/testing environments |

Each category requires:
- **Display name** for user interface presentation
- **Description** explaining the validation level and intended use

### Air-Gapped Specific Requirements

For air-gapped deployments, the catalog must include specialized metadata to support offline operations.

#### Image Management
- **Image digest verification** to ensure image integrity without external registry access
- **Custom image repository mapping** to support private registries

#### Dependency Tracking
- **Network access requirements** to determine appropriate permission profiles
- **Verification dates** to track when servers were last validated

### Tool Configuration Data

To support MCPToolConfig resource creation, the catalog needs comprehensive tool metadata.

#### Tool Metadata
- **Tool names and descriptions** for each server
- **Default tool filters** representing recommended tool subsets for security
- **Tool override definitions** for enterprise renaming and rebranding

#### Security Profiles
- **Recommended resource limits** (CPU/memory) for capacity planning
- **Permission profile mappings** (none/network/custom) for security enforcement
- **Environment variable definitions** with security classifications (secret vs. non-secret)

### Customer Selection Integration

The catalog must support customer customization through configurable metadata.

#### Selection Metadata
- **Server selection state** (which servers customer has chosen)
- **Custom image overrides** for private registry integration
- **Tool filtering preferences** based on organizational security policies
- **Resource requirement customizations** for environment-specific needs

This minimal dataset enables users to obtain all metadata necessary to create the required Kubernetes resources (ConfigMap, MCPRegistry, MCPToolConfig) while maintaining security boundaries and supporting air-gapped operational requirements.

## ConfigMap-Based Registry Deployment

### Registry ConfigMap Structure
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: customer-selected-registry
  namespace: production
data:
  registry.json: |
    {
      "$schema": "https://raw.githubusercontent.com/stacklok/toolhive/main/pkg/registry/data/schema.json",
      "version": "1.0.0",
      "last_updated": "2025-09-24T20:00:00Z",
      "servers": {
        "osv-scanner": {
          "description": "Open Source Vulnerability scanner for security analysis",
          "image": "internal-registry.company.com/osv-mcp/server@sha256:abc123",
          "status": "Active",
          "tier": "Community",
          "transport": "streamable-http",
          "target_port": 8080,
          "tools": ["vulnerability-scan", "security-analysis", "osv-query"],
          "tags": ["security", "vulnerability", "scanning"],
          "permissions": {
            "network": {
              "outbound": {
                "insecure_allow_all": true
              }
            }
          }
        }
      }
    }
```

### MCPRegistry Resource
```yaml
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPRegistry
metadata:
  name: customer-registry
  namespace: production
  labels:
    catalog.toolhive.dev/source: "customer-selection"
    catalog.toolhive.dev/category: "validated"
spec:
  displayName: "Customer Selected MCP Servers"
  enforceServers: true
  source:
    type: configmap
    configmap:
      name: customer-selected-registry
      key: registry.json
  filter:
    tags:
      include: ["security", "web"]  # Based on customer selection
```

## Tool Configuration Management

### MCPToolConfig for Tool Filtering
```yaml
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPToolConfig
metadata:
  name: customer-tool-policy
  namespace: production
  labels:
    catalog.toolhive.dev/generated: "true"
spec:
  toolsFilter:
    - "vulnerability-scan"
    - "security-analysis"
    # Exclude 'osv-query' based on customer security policy
  toolsOverride:
    "vulnerability-scan":
      name: "enterprise-vulnerability-scan"
      description: "Enterprise-grade vulnerability scanning with compliance reporting"
```

## Security Model for Air-Gapped Environments

### Multi-Layer Security
1. **Catalog Level**: Central authority for server definitions
2. **Selection Level**: Customer chooses subset of available servers
3. **Registry Level**: Namespace-scoped with enforcement policies
4. **Tool Level**: Granular tool filtering and renaming

### Access Control Patterns

#### Pattern 1: Namespace Isolation
```yaml
# Production namespace - validated only
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPRegistry
metadata:
  name: validated-registry
  namespace: production
spec:
  enforceServers: true
  filter:
    tags:
      include: ["validated"]
```

#### Pattern 2: RBAC-Based Registry Access
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["customer-selected-registry"]
  verbs: ["get", "list"]
- apiGroups: ["toolhive.stacklok.dev"]
  resources: ["mcpregistries"]
  verbs: ["get", "list"]
```

#### Pattern 3: NetworkPolicy Isolation
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: registry-api-isolation
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: mcp-registry-api
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: "mcp-client"
```

## Registry Architecture

### Automatic API Service Deployment

Each MCPRegistry resource automatically deploys its own API service when created by the ToolHive operator:

```yaml
# MCPRegistry creates its own API endpoint
status:
  apiStatus:
    phase: Ready
    endpoint: "http://mcp-{registry-name}-api.{namespace}.svc.cluster.local:8080"
```

### Distributed Registry Pattern

The architecture uses namespace-scoped registries rather than a centralized registry API:

- **No central registry API** - each MCPRegistry deploys its own API service
- **Namespace isolation** - registries are scoped to specific namespaces
- **User responsibility** - users create MCPRegistry/MCPToolConfig resources using catalog metadata
- **Operator automation** - ToolHive operator handles API service deployment and management

## Implementation Guidelines

### User Workflow
1. **Browse Catalog**: Query catalog API for available validated/community servers
2. **Select Servers**: Choose specific servers and tools based on catalog metadata
3. **Create ConfigMaps**: Manually create ConfigMaps with selected server data
4. **Create MCPRegistry**: Apply MCPRegistry resources pointing to ConfigMaps
5. **Create MCPToolConfig**: Apply tool filtering configurations as needed
6. **Operator Deploys**: ToolHive operator automatically creates registry API services

### Registry Management
1. **ConfigMap Updates**: Modify registry content
2. **Version Control**: Track changes through K8s resource annotations
3. **Sync Management**: Manual sync triggers via annotations
4. **Health Monitoring**: Monitor registry API and sync status

## Benefits of Architecture

1. **Security**: No external network dependencies
2. **Control**: Full control over available servers and tools
3. **Compliance**: Audit trail through K8s resource history
4. **Flexibility**: Easy customization per namespace/environment
5. **Reliability**: No external service dependencies

This architecture provides a robust foundation for enterprise air-gapped deployments while maintaining the flexibility and security required for production environments.