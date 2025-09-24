# ToolHive MCP Registry Architecture Research

## Overview

This repository contains comprehensive research and architecture documentation for integrating a cluster-wide MCP Catalog API with namespace-scoped MCP Registries in air-gapped Kubernetes environments. The research focuses on enterprise deployment patterns, security models, and operational frameworks for MCP server management.

## 🎯 Project Focus

**Primary Objective**: Design and document a robust architecture for MCP server catalog integration that supports:
- Air-gapped enterprise deployments
- Namespace-scoped security isolation  
- User-driven resource creation workflows
- Multi-layer security controls
- Scalable registry management


## 📚 Documentation Structure

### Core Architecture Documentation

The primary deliverable is comprehensive architecture documentation located in [`docs/architecture/`](./docs/architecture/):

#### 🏗️ **Integration Architecture**
- **[Catalog Integration](./docs/architecture/catalog-integration.md)** - Complete integration architecture between cluster-wide catalog and namespace registries
- **[Catalog API Specification](./docs/architecture/catalog-api-specification.md)** - REST API specification for the catalog service

#### 🔧 **Technical References**  
- **[MCPRegistry API Reference](./docs/architecture/mcpregistry-api-reference.md)** - Complete CRD specification and operations guide
- **[MCP Server Deployment Guide](./docs/architecture/mcp-server-deployment-guide.md)** - Comprehensive server deployment and configuration
- **[Operator Architecture Notes](./docs/architecture/operator-architecture-notes.md)** - Key operator behavior and patterns

#### 🔒 **Security Framework**
- **[Security and Access Control Models](./docs/architecture/security-access-control-models.md)** - Multi-layer security architecture with RBAC, network policies, and compliance frameworks

### Supporting Materials

#### 📋 **Operational Resources**
- **[Kubernetes Deployments](./deploy/kubernetes/)** - Working MCPServer examples and cluster configuration
- **[Helm Installation Notes](./deploy/helm/)** - ToolHive operator deployment guidance  
- **[Registry Examples](./registry/)** - Sample registry data and schemas for testing

#### 🛠️ **Development Tools**
- **[Setup Scripts](./scripts/)** - Automation for cluster setup and validation
- **[Advanced Examples](./examples/advanced/)** - Complex configuration patterns
- **[Troubleshooting Guides](./docs/troubleshooting/)** - Common issues and solutions

## 🏗️ **Key Architectural Patterns**

### Air-Gapped Design Principles

1. **ConfigMap-Based Registries** - All registry data stored in Kubernetes ConfigMaps (no Git dependencies)
2. **Private Image Support** - Custom container registries with digest verification  
3. **Offline Operation** - Complete functionality without external network access
4. **User-Driven Workflow** - Catalog provides metadata; users create Kubernetes resources manually

### Security Architecture Layers

```
┌─────────────────────────────────────────────────────┐
│                 Catalog API                         │
│              (Cluster-wide)                         │
│  ┌─────────────────────────────────────────────┐   │
│  │        Authentication & RBAC                │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼ User queries metadata
┌─────────────────────────────────────────────────────┐
│              Namespace Level                        │
│         (User Creates Resources)                    │
│  ┌─────────────────────────────────────────────┐   │
│  │     MCPRegistry Access Control              │   │
│  │   (enforce servers, filtering)              │   │
│  └─────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────┐   │
│  │      Network Policies                       │   │
│  │   (API service isolation)                   │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼ Operator deploys automatically
┌─────────────────────────────────────────────────────┐
│              Server Level                           │
│           (MCP Server Runtime)                      │
│  ┌─────────────────────────────────────────────┐   │
│  │     Permission Profiles                     │   │
│  │   (network, filesystem, capabilities)       │   │
│  └─────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────┐   │
│  │       Tool Filtering                        │   │
│  │   (MCPToolConfig restrictions)              │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### Integration Data Flow

```
User Discovery → Catalog API → Metadata Export → User Creates Resources → Operator Deploys
                                                   ├── ConfigMap (registry data)
                                                   ├── MCPRegistry (deployment spec)  
                                                   └── MCPToolConfig (tool filtering)
                                                                  ↓
                                                   Automatic API Service Deployment
                                                   (per-registry endpoints)
```

## 🎯 **Research Findings**

### Distributed Registry Pattern

The ToolHive operator implements a **distributed registry architecture**:

- **No centralized registry API** - Each MCPRegistry CRD deploys its own API service
- **Namespace isolation** - Registry APIs scoped to specific namespaces
- **Automatic service deployment** - Operator handles API service lifecycle
- **Per-registry endpoints** - Each registry gets its own HTTP API

### Catalog Integration Model

The optimal integration approach identified through this research:

1. **Catalog as Metadata Repository** - Central source of server definitions and configurations
2. **User-Driven Resource Creation** - Users manually create Kubernetes resources using catalog metadata
3. **Operator Automation** - ToolHive operator handles deployment and API service creation
4. **Security Boundaries** - Multiple layers of access control and isolation

### Security Control Points

Three primary security models documented:

1. **Namespace-Based Isolation** - Different security zones with varying trust levels
2. **Role-Based Access Control** - Fine-grained permissions based on user roles
3. **Service Mesh Integration** - Advanced security with mutual TLS and authorization policies

## 🚀 **Getting Started**

### For Hands-On Experience (Recommended First Step)

** Engineers wanting to deploy and experience MCP Registries:**

🎯 **[Complete Deployment Guide](./docs/guides/tasks.md)** - Step-by-step tasks to:
- Set up Kubernetes cluster with ToolHive operator
- Deploy and test MCP servers  
- Create and configure custom registries
- Experience the complete registry workflow

This guide provides copy-paste commands and validation steps for each phase.

### For Architecture Review

1. **Start Here**: [Architecture Overview](./docs/architecture/README.md)
2. **Integration Design**: [Air-Gapped Catalog Integration](./docs/architecture/catalog-integration.md)
3. **API Specification**: [Catalog API Specification](./docs/architecture/catalog-api-specification.md)
4. **Security Framework**: [Security and Access Control Models](./docs/architecture/security-access-control-models.md)

### For Implementation Planning

1. **Registry API Reference**: [MCPRegistry API Reference](./docs/architecture/mcpregistry-api-reference.md)
2. **Server Deployment**: [MCP Server Deployment Guide](./docs/architecture/mcp-server-deployment-guide.md)
3. **Operator Behavior**: [Operator Architecture Notes](./docs/architecture/operator-architecture-notes.md)

### Quick Validation Commands

```bash
# Automated cluster setup
./scripts/setup/setup-cluster.sh

# Install ToolHive operator
helm upgrade -i toolhive-operator-crds oci://ghcr.io/stacklok/toolhive/toolhive-operator-crds
helm upgrade -i toolhive-operator oci://ghcr.io/stacklok/toolhive/toolhive-operator -n toolhive-system --create-namespace

# Test MCPServer deployment
kubectl apply -f deploy/kubernetes/osv-mcpserver.yaml
kubectl get mcpservers

# Validate registry schema
python3 -m json.tool registry/registry.json > /dev/null && echo "Valid JSON"
```

## 📊 **Repository Organization**

```
toolhive-research/
├── docs/architecture/           # 📚 Primary deliverable - complete architecture docs
├── deploy/                      # 🚀 Working Kubernetes manifests and deployment guides
├── registry/                    # 📋 Example registry data and schemas  
├── scripts/                     # 🛠️ Automation for testing and validation
├── examples/advanced/           # 🔧 Advanced configuration patterns
└── docs/troubleshooting/        # 🩺 Operational guidance and issue resolution
```

## 📋 **Implementation Guidance**

### Minimal Catalog Requirements

To support the documented architecture, a catalog system needs:

| **Component** | **Requirement** | **Purpose** |
|---------------|-----------------|-------------|
| **Server Discovery API** | REST endpoints for browsing validated/community servers | User server selection |
| **Metadata Export API** | Complete server specifications including tools, security profiles | Resource creation data |
| **Category Organization** | Validated vs. community server classification | Security zone targeting |
| **Tool Information** | Comprehensive tool definitions with descriptions | MCPToolConfig creation |
| **Air-Gapped Metadata** | Image digests, offline docs, dependency tracking | Enterprise deployment |

### User Workflow

The documented workflow eliminates CLI dependencies:

1. **Query Catalog** - Users browse available servers via catalog API
2. **Export Metadata** - Catalog provides complete resource creation data
3. **Create ConfigMaps** - Users manually create ConfigMaps with selected servers
4. **Deploy MCPRegistry** - Users apply MCPRegistry resources pointing to ConfigMaps
5. **Configure Tools** - Users apply MCPToolConfig for tool filtering (optional)
6. **Automatic Deployment** - ToolHive operator handles API service creation

## 📚 **Reference Materials**

- **[ToolHive Documentation](https://docs.stacklok.com/toolhive/)** - Official ToolHive operator documentation
- **[Model Context Protocol](https://modelcontextprotocol.io/)** - MCP specification and standards
- **[Kubernetes Documentation](https://kubernetes.io/docs/)** - CRD and operator patterns
- **[Air-Gapped Deployment Patterns](https://kubernetes.io/docs/setup/production-environment/tools/)** - Enterprise Kubernetes guidance

## 🤝 **Contributing**

This research repository follows documentation-driven development:

1. **Architecture-First** - All patterns documented before implementation
2. **Security-Focused** - Security implications considered for all design decisions  
3. **Enterprise-Ready** - Patterns validated for production air-gapped environments
4. **Implementation-Agnostic** - Architecture independent of specific technology choices

## 📄 **License**

This research and documentation is provided under the MIT License. Individual component licenses apply to referenced tools and systems.
