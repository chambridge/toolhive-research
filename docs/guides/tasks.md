# Toolhive Model Context Protocol Registry Setup Tasks

## Phase 1: Environment Setup

### Task 1: Prerequisites Verification
- [ ] Verify container runtime: check for Podman first, then Docker as fallback
- [ ] Verify kubectl is installed and configured
- [ ] Verify Helm is installed (latest version)
- [ ] Confirm system requirements for kind cluster
- [ ] Configure kind to use preferred container runtime (Podman if available)

**Copy-paste commands:**
```bash
# Check prerequisites
podman --version && echo "✅ Podman found" || echo "❌ Podman not found"
docker --version && echo "✅ Docker found" || echo "❌ Docker not found"
kubectl version --client
helm version
kind version

# Set preferred container runtime
export KIND_EXPERIMENTAL_PROVIDER=podman  # Use Podman if available
echo 'export KIND_EXPERIMENTAL_PROVIDER=podman' >> ~/.zshrc  # Make persistent
```

### Task 2: Kind Cluster Setup
- [ ] Install kind (Kubernetes in Docker/Podman) if not already installed
- [ ] Create kind cluster configuration file (if custom config needed)
- [ ] Create kind cluster with appropriate node configuration using preferred container runtime
- [ ] Verify cluster is running and accessible via kubectl
- [ ] Test basic cluster functionality

**Copy-paste commands:**
```bash
# Automated cluster setup (recommended)
./scripts/setup/setup-cluster.sh

# OR manual cluster setup
kind create cluster --config deploy/kubernetes/kind-config.yaml

# Verify cluster
kubectl cluster-info
kubectl get nodes
kubectl get pods -A
```

## Phase 2: Toolhive Operator Deployment

### Task 3: Operator Installation Research
- [ ] Review detailed operator deployment documentation at `/toolhive/guides-k8s/deploy-operator-helm`
- [ ] Identify required Helm repository for Toolhive operator
- [ ] Document any custom values or configuration requirements

### Task 4: Deploy Toolhive Operator
- [ ] Add Stacklok Helm repository
- [ ] Update Helm repository cache
- [ ] Install Toolhive operator using Helm
- [ ] Verify operator deployment and pod status
- [ ] Check operator logs for any issues

**Copy-paste commands:**
```bash
# Install CRDs first
helm upgrade -i toolhive-operator-crds \
    oci://ghcr.io/stacklok/toolhive/toolhive-operator-crds

# Install operator
helm upgrade -i toolhive-operator \
    oci://ghcr.io/stacklok/toolhive/toolhive-operator \
    -n toolhive-system --create-namespace

# Verify installation
kubectl get pods -n toolhive-system
kubectl get crd | grep toolhive
kubectl logs -n toolhive-system -l app.kubernetes.io/name=toolhive-operator --tail=10
```

### Task 5: Operator Configuration Validation
- [ ] Verify Custom Resource Definitions (CRDs) are installed
- [ ] Test basic operator functionality
- [ ] Validate telemetry and logging configuration
- [ ] Document any alpha-stage limitations or warnings

## Phase 3: MCP Server Setup

### Task 6: MCP Server Deployment Research
- [ ] Review MCP server deployment guide at `/toolhive/guides-k8s/run-mcp-k8s`
- [ ] Understand MCPServer CRD structure and requirements
- [ ] Identify available MCP server images for testing

### Task 7: Deploy Test MCP Server
- [ ] Create MCPServer custom resource definition
- [ ] Deploy a basic MCP server (e.g., gofetch example)
- [ ] Verify MCP server pod deployment and status
- [ ] Test MCP server connectivity and functionality

## Phase 4: Custom Registry Implementation

### Task 8: Registry Structure Setup
- [ ] Create dedicated directory for custom registry
- [ ] Download and review JSON schema from Stacklok repository
- [ ] Plan registry structure and server configurations

### Task 9: Create Registry Configuration
- [ ] Create registry.json file with proper schema reference
- [ ] Define metadata (version, last updated, etc.)
- [ ] Configure at least one MCP server entry
- [ ] Validate JSON syntax and schema compliance

### Task 10: Registry Server Configuration
- [ ] Define server descriptions and metadata
- [ ] Specify container images and transport methods
- [ ] Configure network permissions and security settings
- [ ] Document tool capabilities for each server

## Phase 5: Integration and Testing

### Task 11: ToolHive CLI Setup
- [ ] Install ToolHive CLI (thv command)
- [ ] Configure CLI to use custom registry
- [ ] Verify registry configuration with `thv config get-registry`
- [ ] Test registry listing with `thv registry list`

### Task 12: End-to-End Testing
- [ ] Deploy MCP servers from custom registry
- [ ] Test server functionality and tool access
- [ ] Verify network connectivity and permissions
- [ ] Document any issues or limitations

### Task 13: Advanced Configuration (Optional)
- [ ] Implement server groups for organization
- [ ] Configure environment variables for servers
- [ ] Set up secret management for sensitive data
- [ ] Add monitoring and logging for registry usage

## Phase 6: Documentation and Cleanup

### Task 14: Documentation
- [ ] Document complete setup process
- [ ] Record any deviations from official documentation
- [ ] Note alpha-stage limitations and workarounds
- [ ] Create troubleshooting guide for common issues

### Task 15: Validation and Cleanup
- [ ] Perform full system test from clean state
- [ ] Document cleanup procedures
- [ ] Create backup of working configurations
- [ ] Plan for production deployment considerations

## Notes and Considerations

### Container Runtime Preferences
- **Preferred**: Podman (if available) - rootless, daemonless, more secure
- **Fallback**: Docker - if Podman not available
- **Kind Configuration**: Use `KIND_EXPERIMENTAL_PROVIDER=podman` environment variable for Podman
- **Verification Commands**:
  - Check Podman: `podman --version`
  - Check Docker: `docker --version`
  - Configure kind: `export KIND_EXPERIMENTAL_PROVIDER=podman` (if using Podman)

### Important Warnings
- Toolhive operator is marked as "Experimental" - not for production use
- MCPServer CRD is in alpha state - expect breaking changes
- Monitor for updates and breaking changes in documentation

### Testing Strategy
- Test each phase incrementally
- Validate functionality before proceeding to next phase
- Keep detailed logs of commands and outputs
- Plan rollback procedures for each major step

### Security Considerations
- Use secure container images from trusted sources
- Implement proper RBAC for Kubernetes resources
- Consider network policies for MCP server communication
- Plan secret management strategy for production use
- Podman provides additional security benefits (rootless operation)