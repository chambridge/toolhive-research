# ToolHive MCP Registry Architecture Documentation

## Overview

This directory contains comprehensive architecture documentation for integrating a cluster-wide MCP Catalog API with namespace-scoped MCP Registries in air-gapped environments.

## Documentation Structure

### Core Architecture Documents

#### [Air-Gapped Catalog Integration](./catalog-integration.md)
Outlines the complete integration architecture between a cluster-wide MCP Catalog API and namespace-scoped MCP Registries. Covers:
- Air-gapped architecture constraints and solutions
- ConfigMap-based registry deployment (no Git dependencies)
- Catalog to registry data flow
- User workflow for manual resource creation

#### [Catalog API Specification](./catalog-api-specification.md) 
Comprehensive API specification for the cluster-wide MCP Catalog service. Includes:
- Complete REST API endpoints and data models
- Server discovery and filtering capabilities
- Metadata export for user resource creation
- Authentication and authorization requirements

#### [MCPRegistry API Reference](./mcpregistry-api-reference.md)
Complete reference for the MCPRegistry Custom Resource Definition and its associated APIs. Covers:
- CRD specification with all fields and options
- Registry data schema and format requirements
- Automatic API service endpoints and operations
- Operational examples and troubleshooting

#### [MCP Server Deployment Guide](./mcp-server-deployment-guide.md)
Comprehensive guide for deploying MCP servers using the ToolHive operator. Includes:
- Available MCP servers (OSV Scanner, GoFetch) with complete configurations
- MCPServer CRD specifications and transport options
- Deployment examples and monitoring guidance
- Security considerations and catalog integration requirements

#### [Security and Access Control Models](./security-access-control-models.md)
Comprehensive security architecture with multiple access control models. Includes:
- Multi-layer security architecture (catalog → namespace → server → tool)
- Three access control models: namespace-based, role-based, and service mesh
- Network policies and permission profiles
- Audit, compliance, and monitoring strategies

## Key Architectural Concepts

### Air-Gapped Design Principles

1. **No External Dependencies**: All registry data stored in ConfigMaps within the cluster
2. **Private Image Registries**: Support for custom container registries with image verification
3. **Offline Documentation**: Local documentation and help resources
4. **Version Control**: Git-free operation with K8s-native versioning

### Security Architecture Layers

```
Catalog API (Cluster-wide)
├── Authentication & Authorization (RBAC)
├── Namespace Isolation
│   ├── MCPRegistry Access Control
│   ├── Network Policies
│   └── ConfigMap Security
└── Server Runtime Security
    ├── Permission Profiles
    ├── Tool Filtering (MCPToolConfig)
    └── Runtime Monitoring
```

### Data Flow Architecture

```
User Query → Catalog API → Metadata Export → User Creates Resources → Namespace Deployment
                                             ├── ConfigMap (registry data)
                                             ├── MCPRegistry (deployment spec)
                                             └── MCPToolConfig (tool filtering)
```

## Integration Points

### Catalog API → MCPRegistry Integration

The Catalog API serves as the central metadata repository for MCP server definitions while MCPRegistry provides namespace-scoped deployment and management. Key integration points:

1. **Server Discovery**: Catalog aggregates from multiple sources (validated/community)
2. **Metadata Export**: API provides complete server metadata for resource creation
3. **User Resource Creation**: Users manually create ConfigMaps, MCPRegistry, and MCPToolConfig
4. **Operator Automation**: ToolHive operator handles automatic API service deployment
5. **Security Enforcement**: Namespace-level policies and tool restrictions

### Registry Schema Compatibility

Both systems use the same underlying registry schema with extensions for air-gapped environments:
- **Standard Fields**: Compatible with upstream ToolHive registry format
- **Air-Gapped Extensions**: Additional metadata for offline operation
- **Security Metadata**: Enhanced permission and compliance information

## Deployment Patterns

### Pattern 1: Single Registry per Namespace
- One MCPRegistry resource per namespace
- Clear ownership and security boundaries
- Simplified RBAC and network policies

### Pattern 2: Multi-Registry per Namespace
- Separate registries for different categories (validated/community)
- Enhanced filtering and organization
- More complex but flexible security model

### Pattern 3: Hierarchical Registries
- Base registry with filtered overlays
- Inheritance of server definitions
- Centralized management with local customization

## Security Considerations

### Access Control Models

1. **Namespace-Based**: Different security zones with varying trust levels
2. **Role-Based**: Fine-grained control based on user roles and responsibilities

### Tool-Level Security

- **MCPToolConfig**: Runtime filtering and tool renaming
- **Permission Profiles**: Container security contexts and capabilities
- **Network Policies**: Ingress/egress control for MCP servers

## Getting Started

1. **Review Architecture**: Start with [Air-Gapped Catalog Integration](./catalog-integration.md)
2. **Understand APIs**: Read [Catalog API Specification](./catalog-api-specification.md)
3. **Deploy Registries**: Follow [MCPRegistry API Reference](./mcpregistry-api-reference.md)
4. **Implement Security**: Apply [Security and Access Control Models](./security-access-control-models.md)

## Related Documentation

- **MCP Server Deployment**: [mcp-server-deployment-guide.md](./mcp-server-deployment-guide.md)
- **Operator Architecture**: [operator-architecture-notes.md](./operator-architecture-notes.md)

## Contributing

When updating this architecture documentation:

1. Maintain consistency across all documents
2. Update cross-references when adding new content
3. Include practical examples and operational guidance
4. Consider security implications of any changes
5. Test examples in actual deployments

This architecture provides a robust foundation for enterprise-grade MCP server management in air-gapped Kubernetes environments while maintaining security, flexibility, and operational control.