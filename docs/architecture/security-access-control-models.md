# Security and Access Control Models for MCP Registry

## Overview

This document outlines comprehensive security models and access control mechanisms for MCP Registry deployments in air-gapped environments. The security model implements defense-in-depth principles with multiple layers of protection.

## Security Architecture Layers

```
┌─────────────────────────────────────────────────┐
│                 Catalog API                     │
│              (Cluster-wide)                     │
│  ┌─────────────────────────────────────────┐   │
│  │        Authentication & RBAC            │   │
│  │      (who can access what?)             │   │
│  └─────────────────────────────────────────┘   │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│              Namespace Level                    │
│         (Registry Deployment)                   │
│  ┌─────────────────────────────────────────┐   │
│  │     MCPRegistry Access Control          │   │
│  │   (enforce servers, filtering)          │   │
│  └─────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────┐   │
│  │      Network Policies                   │   │
│  │   (API service isolation)               │   │
│  └─────────────────────────────────────────┘   │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│              Server Level                       │
│           (MCP Server Runtime)                  │
│  ┌─────────────────────────────────────────┐   │
│  │     Permission Profiles                 │   │
│  │   (network, filesystem, capabilities)   │   │
│  └─────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────┐   │
│  │       Tool Filtering                    │   │
│  │   (MCPToolConfig restrictions)          │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

## Access Control Models

### Model 1: Namespace-Based Isolation (Recommended)

**Use Case:** Different security zones with varying trust levels

```yaml
# Production namespace - validated servers only
apiVersion: v1
kind: Namespace
metadata:
  name: production-mcp
  labels:
    security-level: "high"
    mcp-enforcement: "strict"
---
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPRegistry
metadata:
  name: validated-registry
  namespace: production-mcp
spec:
  displayName: "Production Validated Servers"
  enforceServers: true
  source:
    type: configmap
    configmap:
      name: validated-servers-data
  filter:
    tags:
      include: ["validated", "security-approved"]
      exclude: ["experimental", "community"]
```

```yaml
# Development namespace - broader access
apiVersion: v1
kind: Namespace
metadata:
  name: development-mcp
  labels:
    security-level: "medium"
    mcp-enforcement: "permissive"
---
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPRegistry
metadata:
  name: community-registry
  namespace: development-mcp
spec:
  displayName: "Development and Community Servers"
  enforceServers: false
  source:
    type: configmap
    configmap:
      name: community-servers-data
```

**RBAC Configuration:**
```yaml
# Production access - limited to specific users
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production-mcp
  name: mcp-production-admin
rules:
- apiGroups: ["toolhive.stacklok.dev"]
  resources: ["mcpregistries", "mcpservers", "mcptoolconfigs"]
  verbs: ["get", "list", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["validated-servers-data"]
  verbs: ["get", "list", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: production-mcp-admin
  namespace: production-mcp
subjects:
- kind: User
  name: security-team-lead
  apiGroup: rbac.authorization.k8s.io
- kind: Group
  name: production-engineers
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: mcp-production-admin
  apiGroup: rbac.authorization.k8s.io
```

### Model 2: Role-Based Registry Access

**Use Case:** Fine-grained control based on user roles

```yaml
# Registry Admin - full control
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: mcp-registry-admin
rules:
- apiGroups: ["toolhive.stacklok.dev"]
  resources: ["mcpregistries"]
  verbs: ["*"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["create", "get", "list", "update", "patch", "delete"]
---
# Registry User - read-only access
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: mcp-registry-user
rules:
- apiGroups: ["toolhive.stacklok.dev"]
  resources: ["mcpregistries"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get"]
  resourceNames: ["mcp-*-api"]
---
# Server Deployer - can deploy servers from registry
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: mcp-server-deployer
rules:
- apiGroups: ["toolhive.stacklok.dev"]
  resources: ["mcpservers", "mcptoolconfigs"]
  verbs: ["create", "get", "list", "update", "patch"]
- apiGroups: ["toolhive.stacklok.dev"]
  resources: ["mcpregistries"]
  verbs: ["get", "list"]
```

## Network Security

### Network Policies for Registry API Isolation

```yaml
# Deny all ingress by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: production-mcp
spec:
  podSelector: {}
  policyTypes:
  - Ingress
---
# Allow specific access to registry API
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: mcp-registry-api-access
  namespace: production-mcp
spec:
  podSelector:
    matchLabels:
      app: mcp-registry-api
  policyTypes:
  - Ingress
  ingress:
  # Allow catalog API access
  - from:
    - namespaceSelector:
        matchLabels:
          name: catalog-system
      podSelector:
        matchLabels:
          app: catalog-api
    ports:
    - protocol: TCP
      port: 8080
  # Allow same-namespace access
  - from:
    - namespaceSelector:
        matchLabels:
          name: production-mcp
    ports:
    - protocol: TCP
      port: 8080
```

## Permission Profiles and Security Contexts

### Built-in Permission Profiles

```yaml
# Network permission profile
apiVersion: v1
kind: ConfigMap
metadata:
  name: network-permission-profile
  namespace: toolhive-system
data:
  profile.yaml: |
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      runAsGroup: 1000
      fsGroup: 2000
      capabilities:
        drop:
        - ALL
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
    networkPolicy:
      egress:
        allowDNS: true
        allowHTTPS: true
        allowSpecificHosts: []
```

### Custom Security Profiles

```yaml
# High-security profile for validated servers
apiVersion: v1
kind: ConfigMap
metadata:
  name: high-security-profile
  namespace: production-mcp
data:
  profile.yaml: |
    securityContext:
      runAsNonRoot: true
      runAsUser: 1000
      runAsGroup: 1000
      fsGroup: 2000
      capabilities:
        drop:
        - ALL
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      seccompProfile:
        type: RuntimeDefault
    podSecurityPolicy:
      seLinuxProfile:
        type: RuntimeDefault
    networkPolicy:
      egress:
        allowDNS: true
        allowSpecificHosts:
        - "api.osv.dev"
        - "nvd.nist.gov"
        denyAll: true
```

## Tool-Level Security Controls

### MCPToolConfig Security Restrictions

```yaml
# Security-focused tool configuration
apiVersion: toolhive.stacklok.dev/v1alpha1
kind: MCPToolConfig
metadata:
  name: security-tool-restrictions
  namespace: production-mcp
spec:
  # Only allow approved security tools
  toolsFilter:
    - "vulnerability-scan"
    - "security-analysis"
    - "compliance-check"
  # Rename sensitive tools
  toolsOverride:
    "osv-query":
      name: "enterprise-vuln-query"
      description: "Enterprise vulnerability database query with audit logging"
    "security-analysis":
      name: "compliance-security-scan"
      description: "Security analysis with compliance reporting"
```

## Audit and Compliance

### Audit Policy for MCP Resources

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
# Log all MCP registry modifications
- level: RequestResponse
  namespaces: ["production-mcp"]
  resources:
  - group: "toolhive.stacklok.dev"
    resources: ["mcpregistries", "mcpservers", "mcptoolconfigs"]
  verbs: ["create", "update", "patch", "delete"]
# Log access to registry ConfigMaps
- level: Metadata
  namespaces: ["production-mcp"]
  resources:
  - group: ""
    resources: ["configmaps"]
    resourceNames: ["*-registry-data"]
  verbs: ["get", "list"]
```

This comprehensive security model provides multiple layers of protection while maintaining the flexibility needed for MCP registry deployments. The modular approach allows organizations to implement security controls appropriate for their specific risk tolerance and compliance requirements.