# Homelab Troubleshooting & Technical Solutions

> **Last Updated**: August 25, 2025

## Networking & Load Balancing Solutions

### Cross-Node Pod Connectivity Issue

**Problem**: Traefik returning 502 Bad Gateway errors when routing to backend services across different k3s nodes in a Tailscale mesh network.

**Root Cause**: Flannel VXLAN backend over Tailscale doesn't properly support cross-node pod-to-pod traffic.

**Symptoms**:
- Traefik logs showing `dial tcp 10.42.x.x:80: connect: connection refused`
- Services work within same node, fail across nodes
- Service VIP connectivity works, direct pod IP connectivity fails

**Investigation Steps**:
1. **Pod-to-pod connectivity test**:
   ```bash
   # From Traefik pod to backend pod (different nodes)
   kubectl exec -n traefik traefik-pod -- wget -qO- http://10.42.0.20:80
   # Result: Connection refused
   ```

2. **Service VIP connectivity test**:
   ```bash
   # From Traefik pod to service VIP
   kubectl exec -n traefik traefik-pod -- wget -qO- http://10.43.88.207:80  
   # Result: Works perfectly
   ```

3. **Network analysis**:
   - Flannel backend: VXLAN over Tailscale interfaces
   - Cross-node VXLAN encapsulation doesn't traverse Tailscale properly
   - Service-based routing uses kube-proxy which handles cross-node correctly

### Solution: Traefik IngressRoute with Native Load Balancing

**Implementation**: Use Traefik's native IngressRoute CRD with `nativeLB: true` instead of standard Kubernetes Ingress.

**Before (Standard Ingress)**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app
spec:
  rules:
    - host: example.com
      http:
        paths:
          - backend:
              service:
                name: my-app
                port:
                  number: 80
```

**After (IngressRoute with nativeLB)**:
```yaml
apiVersion: traefik.containo.us/v1alpha1
kind: IngressRoute
metadata:
  name: my-app
spec:
  entryPoints:
    - websecure
  routes:
    - match: Host(`example.com`)
      kind: Rule
      services:
        - name: my-app
          port: 80
          nativeLB: true  # Key setting - forces service VIP routing
          strategy: RoundRobin
  tls:
    secretName: my-app-tls
```

**Key Benefits**:
- ✅ Forces Traefik to use service VIP instead of direct pod IPs
- ✅ Eliminates need for duplicate/ExternalName services
- ✅ Works reliably across all node configurations
- ✅ Maintains all Traefik features (TLS, middleware, etc.)
- ✅ Clean, maintainable configuration

**Verification**:
```bash
# Check Traefik logs for load-balancer creation
kubectl logs -n traefik traefik-pod | grep "Creating server"
# Should show: "Creating server 0 http://10.43.88.207:80" (service VIP)
# Not: "Creating server 0 http://10.42.0.20:80" (pod IP)
```

### Alternative Solutions Considered

1. **ExternalName Service Workaround**:
   - Creates duplicate services pointing to original service FQDN
   - Works but clutters namespace with unnecessary resources
   - Harder to maintain and understand

2. **Flannel Backend Change**:
   - Attempted to change from VXLAN to host-gw backend
   - Requires cluster restart and may not work reliably over Tailscale
   - More complex and risky

3. **Service Mesh (Istio/Linkerd)**:
   - Overkill for this specific issue
   - Adds significant complexity
   - Not justified for homelab scale

## Infrastructure Architecture Decisions

### Multi-Node k3s over Tailscale

**Design Choice**: Deploy k3s cluster across geographically distributed nodes using Tailscale mesh networking.

**Benefits**:
- ✅ Secure encrypted networking without VPN complexity
- ✅ Automatic NAT traversal and firewall handling
- ✅ Easy addition of new nodes anywhere
- ✅ Zero-trust network architecture

**Considerations**:
- ⚠️ Flannel VXLAN doesn't work optimally over Tailscale
- ⚠️ Requires careful service discovery configuration
- ⚠️ Network latency between geographically distant nodes

### GitOps with FluxCD

**Design Choice**: Use FluxCD for GitOps-driven deployments instead of manual kubectl/Helm.

**Benefits**:
- ✅ Declarative infrastructure management
- ✅ Automatic reconciliation and drift detection
- ✅ Version controlled infrastructure changes
- ✅ Easy rollback and audit trails

**Implementation Notes**:
- Bootstrap process creates minimal initial state
- All subsequent changes managed through Git
- External Secrets Operator handles dynamic secret injection
- Proper dependency ordering through Kustomizations

## Common Troubleshooting Commands

### Cluster Health Check
```bash
# Check all pods across namespaces
kubectl get pods -A --field-selector=status.phase=Running

# Check Flux reconciliation status
kubectl get gitrepository -A
kubectl get kustomization -A
kubectl get helmrelease -A

# Check certificate status
kubectl get certificates -A
```

### Networking Debugging
```bash
# Test service connectivity from pod
kubectl exec -n namespace pod-name -- wget -qO- http://service.namespace.svc.cluster.local

# Check service endpoints
kubectl get endpoints -n namespace service-name

# Debug with netshoot container
kubectl run netshoot --rm -it --image=nicolaka/netshoot -- /bin/bash
```

### Traefik Debugging
```bash
# Check Traefik logs for routing decisions
kubectl logs -n traefik -l app.kubernetes.io/name=traefik

# Check IngressRoute status
kubectl get ingressroute -A
kubectl describe ingressroute -n namespace name
```

### Secret Management
```bash
# Check External Secrets status
kubectl get externalsecret -A
kubectl get secretstore -A

# Check if secrets are properly injected
kubectl get secret -A | grep -v "kubernetes.io"
```

## Best Practices

1. **Always use service-based routing** for multi-node clusters
2. **Test connectivity manually** before applying configurations
3. **Use IngressRoute CRD** instead of standard Ingress for Traefik
4. **Monitor Traefik logs** during initial deployment and troubleshooting
5. **Keep networking simple** - avoid unnecessary complexity
6. **Document solutions** for future reference

---

This document serves as a reference for troubleshooting similar issues and understanding the technical decisions made in this homelab infrastructure.
