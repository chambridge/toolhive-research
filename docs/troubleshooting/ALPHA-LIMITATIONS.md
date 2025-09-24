# Alpha-Stage Limitations and Workarounds

## ⚠️ Critical Alpha-Stage Warnings

### Toolhive Operator Status: EXPERIMENTAL
**Official Warning**: "Experimental - not recommended for production use"

**Implications**:
- API instability expected
- Breaking changes possible between versions  
- Limited support for production workloads
- Feature set may change significantly

**Workaround Strategy**:
- Pin specific versions in all configurations
- Comprehensive testing before any version upgrades
- Maintain rollback capabilities
- Monitor release notes for breaking changes

## 📚 MCPServer CRD API Instability

### Current State: v1alpha1
**Risk Level**: HIGH - Alpha APIs have no stability guarantees

**Specific Limitations**:
- Field names may change without notice
- Required fields may be added/removed
- Validation rules may become stricter
- Resource behavior may change

**Observed API Elements at Risk**:
```yaml
apiVersion: toolhive.stacklok.dev/v1alpha1  # ⚠️ Alpha API
kind: MCPServer
spec:
  permissionProfile:    # May change structure
  oidcConfig:          # Authentication model may evolve  
  authzConfig:         # Authorization model may change
  telemetry:           # Observability features unstable
```

**Mitigation Strategies**:
1. **Version Pinning**: Always specify exact API versions
2. **Validation**: Test deployments in staging before production
3. **Documentation**: Maintain current API reference locally
4. **Monitoring**: Watch for deprecation warnings in logs

## 🔧 Component Version Mismatches

### Current Version Inconsistencies
**Operator Version**: v0.3.5
**Helm Chart Version**: 0.2.18
**CLI Version**: v0.3.5

**Impact**: Potential compatibility issues between components

**Monitoring Required**:
```bash
# Check for version consistency
kubectl get deployment -n toolhive-system toolhive-operator -o jsonpath='{.metadata.labels.app\.kubernetes\.io/version}'
thv version
helm list -n toolhive-system
```

**Workaround**:
- Document working version combinations
- Test version upgrades in isolation
- Maintain version compatibility matrix

## 🏗️ Resource Management Limitations

### Unexpected Resource Creation Patterns
**Expected**: Simple pod + service creation
**Reality**: Complex resource topology

**Created Resources per MCPServer**:
- Deployment (proxy component)
- StatefulSet (actual MCP server)
- Service (proxy endpoint)
- Service (headless for StatefulSet)
- ServiceAccount (2x - proxy and server)
- Role + RoleBinding (RBAC)

**Implications**:
- Higher resource consumption than expected
- Complex cleanup requirements
- Potential resource conflicts in constrained environments

**Workarounds**:
```bash
# Monitor all created resources
kubectl get all,serviceaccount,role,rolebinding -l mcpserver=<name>

# Clean up resources manually if needed
kubectl delete mcpserver <name>
# Verify all resources removed
```

## 🔐 Security Model Constraints

### Image Verification Limitations
**Current Behavior**: Warns about missing provenance but continues deployment

```
WARN: MCP server has no provenance information set, skipping image verification
```

**Security Implications**:
- No cryptographic verification of container images
- Supply chain security not enforced
- Potential for malicious image deployment

**Workarounds**:
1. **Manual Verification**: Verify image sources manually
2. **Known Registries**: Only use images from trusted registries
3. **Image Scanning**: Implement external image scanning
4. **Network Policies**: Restrict image pull sources

### Permission Model Simplicity
**Current Options**: Limited to `"none"` and `"network"` builtin profiles

**Limitations**:
- No fine-grained network controls in builtin profiles
- `insecure_allow_all` too permissive for production
- Limited filesystem access controls

**Production Workarounds**:
```yaml
# Custom permission profile via ConfigMap
permissionProfile:
  type: configmap
  name: custom-permissions
```

## 🌐 Network Configuration Issues

### Registry Network Access
**Current Implementation**: `"insecure_allow_all": true`

**Security Concerns**:
- Unrestricted outbound access
- No allowlist-based filtering
- Potential for data exfiltration

**Production Hardening Required**:
```json
{
  "permissions": {
    "network": {
      "outbound": {
        "allow_host": [
          "api.osv.dev",
          "github.com",
          "ghcr.io"
        ],
        "allow_port": [80, 443]
      }
    }
  }
}
```

### Transport Protocol Limitations
**Observed Issues**:
- Inconsistent endpoint behaviors between transport types
- Limited protocol documentation
- Different debugging capabilities per transport

**Transport-Specific Limitations**:

#### stdio Transport
- Requires SSE proxy for HTTP access
- More complex debugging
- Session management required

#### streamable-http Transport  
- Direct HTTP access
- Simpler connectivity testing
- Better for HTTP-based tools

#### sse Transport
- Real-time capabilities
- Persistent connection overhead
- Browser compatibility requirements

## 📊 Monitoring and Observability Gaps

### Limited Built-in Observability
**Current State**: Basic health endpoints only

**Missing Features**:
- Detailed metrics exposure
- Request/response tracing
- Performance monitoring
- Error rate tracking

**Alpha-Stage Limitations**:
- OpenTelemetry integration incomplete
- Custom metrics not supported
- Log aggregation basic
- Alerting capabilities absent

**Workarounds**:
```bash
# Manual monitoring approach
curl -s http://localhost:PORT/health | jq .

# Log monitoring
tail -f ~/Library/Application\ Support/toolhive/logs/<workload>.log

# Container monitoring  
podman stats <container-name>
```

## 🔄 API Evolution Tracking

### Breaking Changes Expected
**Areas of High Change Risk**:

1. **Authentication/Authorization**:
   - OIDC configuration structure
   - Permission profile definitions
   - Role-based access controls

2. **Resource Specifications**:
   - Container resource requirements
   - Volume mounting syntax
   - Environment variable handling

3. **Network Configuration**:
   - Transport protocol definitions
   - Proxy configuration options
   - Service mesh integration

4. **Observability**:
   - Telemetry configuration
   - Logging format changes
   - Metrics collection methods

### Change Detection Strategy
```bash
# Monitor for API deprecation warnings
kubectl get events --field-selector type=Warning

# Track version annotations
kubectl get mcpserver -o yaml | grep -A5 -B5 "apiVersion\|version"

# Compare CRD schemas between versions
kubectl get crd mcpservers.toolhive.stacklok.dev -o yaml > current-schema.yaml
```

## 🏭 Production Deployment Blockers

### Current Blockers for Production Use

1. **API Stability**: v1alpha1 APIs not production-ready
2. **Security Model**: Insufficient fine-grained controls
3. **Observability**: Limited monitoring capabilities
4. **Documentation**: Incomplete production guidance
5. **Support**: Experimental status limits support options

### Migration Path to Production

**Phase 1: Enhanced Testing**
- Comprehensive testing in staging environments
- Load testing and performance validation
- Security penetration testing
- Disaster recovery testing

**Phase 2: Security Hardening**
- Custom permission profiles
- Image signature verification
- Network policy implementation
- Secret management integration

**Phase 3: Production Readiness**
- Wait for beta/stable API versions
- Implement comprehensive monitoring
- Establish support procedures
- Create incident response plans

## 📈 Alpha-Stage Monitoring Checklist

### Pre-Production Validation
- [ ] All component versions documented and tested together
- [ ] Breaking change impact assessment completed
- [ ] Security model reviewed and hardened
- [ ] Monitoring and alerting implemented
- [ ] Backup and recovery procedures tested
- [ ] Incident response plan created

### Ongoing Monitoring
- [ ] Release notes reviewed for each version
- [ ] API deprecation warnings monitored
- [ ] Security vulnerabilities tracked
- [ ] Performance metrics collected
- [ ] Error rates monitored
- [ ] Resource utilization tracked

## 🎯 Recommended Timeline for Production

**Short Term (1-3 months)**:
- Continue development and testing with current alpha versions
- Implement security hardening measures
- Develop comprehensive monitoring

**Medium Term (3-6 months)**:
- Evaluate beta API releases
- Migrate to stable API versions when available
- Implement production-grade security controls

**Long Term (6+ months)**:
- Full production deployment with stable APIs
- Enterprise features and support
- Advanced observability and automation

## 💡 Key Takeaways

1. **Alpha Software Appropriate for Development**: Current state suitable for development and testing
2. **Production Use Requires Caution**: Comprehensive risk assessment needed for production deployment
3. **Version Pinning Critical**: Exact version specifications required for stability
4. **Security Hardening Essential**: Default configurations insufficient for production
5. **Monitoring Strategy Required**: Proactive monitoring for API changes and deprecations

The alpha-stage limitations are well-documented and manageable with proper planning and precautions. The software shows strong potential but requires careful handling in production environments.