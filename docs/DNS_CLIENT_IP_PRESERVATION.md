# DNS Client IP Preservation Analysis

**Date**: September 14, 2025  
**Context**: HomeHub DNS infrastructure with authoritative CoreDNS server  
**Problem**: Preserve client IP information in DNS logs while maintaining reliable DNS functionality  

## Architecture Overview

```
External Clients
    ↓ (DNS queries port 53)
VPS Edge Gateway (198.55.102.244)
    ↓ (WireGuard tunnel)
K3s Cluster (192.168.50.x)
    ↓ (NodePort 31053/31054)
CoreDNS Authoritative Server
```

## Current Working Solution: MASQUERADE + DNAT

### Configuration
- **Edge Gateway**: nftables DNAT rules forward port 53 → WireGuard tunnel → CoreDNS NodePorts
- **NAT Method**: MASQUERADE all WireGuard traffic (oif "wg0" masquerade)
- **Result**: Reliable DNS functionality, client IPs shown as 10.172.90.2 in CoreDNS logs

### Why This Works
- **Asymmetric Routing Solution**: MASQUERADE ensures return path for DNS responses
- **Simple & Reliable**: Battle-tested networking approach
- **Low Latency**: Direct packet forwarding without additional hops

## Attempted Alternatives & Their Challenges

### 1. Selective SNAT Approach ❌

**Theory**: Only SNAT external (non-RFC1918) traffic while preserving internal client IPs

```bash
# Attempted nftables rules
oif "wg0" ip saddr != @rfc1918 udp dport 31053 snat to 10.172.90.2
oif "wg0" ip saddr != @rfc1918 tcp dport 31054 snat to 10.172.90.2
```

**Issues Encountered**:
- **Complex nftables syntax**: Set notation `@rfc1918` vs individual conditions  
- **Interface reference problems**: Interface numbers (619) vs names ("wg0") after service restarts
- **Asymmetric routing timeouts**: External traffic couldn't find return path
- **Policy routing complexity**: Added `ip rule` entries but didn't solve core routing issue

**Root Cause**: Asymmetric routing - external clients' packets reach CoreDNS but responses can't find the correct path back without SNAT.

### 2. DNS Proxy (dnsdist) Approach ❌

**Theory**: Run dnsdist on VPS to proxy DNS queries while preserving client IPs

**Implementation**:
- Installed dnsdist on VPS listening on port 53
- Configured backend: `newServer("10.172.90.1:31053")`
- Removed nftables DNAT rules to force traffic through dnsdist
- Added Lua logging to capture client IPs

**Issues Encountered**:
- **Backend connectivity failure**: dnsdist couldn't reach CoreDNS through WireGuard tunnel
- **MASQUERADE interference**: Return path issues for dnsdist's own traffic to backends
- **Configuration complexity**: Permission issues with log files, syslog integration
- **Port conflicts**: dnsdist vs nftables DNAT competing for port 53

**Root Cause**: WireGuard tunnel routing doesn't work well for locally originated traffic (dnsdist) when MASQUERADE is applied to the same interface.

### 3. Policy-Based Routing Attempt ❌

**Theory**: Use IP routing tables to handle asymmetric routing without SNAT

**Implementation**:
```bash
ip route add default via 10.172.90.2 dev wg0 table 100
ip rule add from all sport 31053 table 100  
ip rule add from all sport 31054 table 100
```

**Issues**: 
- Policy rules added successfully but didn't resolve timeouts
- Return path still problematic without source NAT
- Added complexity without solving fundamental asymmetric routing issue

## Technical Root Causes

### 1. Asymmetric Routing Problem
- **Forward path**: External client → VPS → WireGuard → CoreDNS ✅
- **Return path**: CoreDNS → WireGuard → ??? → External client ❌
- **Solution**: MASQUERADE makes VPS the apparent source, ensuring symmetric routing

### 2. WireGuard + NAT Interaction
- WireGuard expects point-to-point communication
- MASQUERADE works because it makes all traffic appear to originate from the VPS
- Selective SNAT breaks this model for some traffic flows

### 3. CoreDNS NodePort Limitations
- CoreDNS running as Kubernetes service on NodePorts (31053/31054)
- Kubernetes networking adds another layer of NAT/routing complexity
- Original client IP already lost at Kubernetes ingress level

## Key Insights & Lessons Learned

### 1. WireGuard Circular Dependency
- **Problem**: WireGuard endpoint was `wg.kragh.dev:51820` 
- **Issue**: DNS name resolved by our own DNS server → circular dependency
- **Solution**: Changed to IP address `192.168.50.16:51820`

### 2. nftables Interface References
- Interface names vs numbers change after service restarts
- Always restart nftables after WireGuard changes: `systemctl restart nftables`
- Use quoted interface names in rules: `oif "wg0"`

### 3. Kubernetes Networking Reality
- Client IPs already lost at K3s ingress level (showing as 10.42.0.1 in CoreDNS logs)
- True client IP preservation would require changes to entire K3s network stack
- External NAT is just one layer in a complex networking stack

## Alternative Client Visibility Options

Since true client IP preservation in DNS logs is challenging, consider these alternatives:

### 1. Edge Gateway Logging
```bash
# nftables logging for DNS queries
nft add rule inet filter input udp dport 53 log prefix \"DNS_QUERY: \"
```

### 2. HAProxy Access Logs
- HTTP/HTTPS traffic preserves client IPs via PROXY protocol
- More valuable for web application analytics

### 3. Application-Level Monitoring
- Traefik access logs with real client IPs
- Application metrics and user analytics
- DNS query pattern analysis vs individual client tracking

### 4. Network Flow Analysis
- Monitor connection patterns at edge gateway
- Aggregate analytics rather than per-query tracking

## Recommendations for Future

### Short Term: Keep Current Solution
- **MASQUERADE + DNAT** approach is production-ready
- Reliable, performant, and maintainable
- Focus on application-level client IP preservation where it matters more

### Long Term: Consider Architectural Changes
- **Dedicated DNS VPS**: Run authoritative DNS directly on VPS (no tunnel)
- **Anycast DNS**: Multiple geographic locations for better client locality
- **DNS Analytics Platform**: Dedicated tools for DNS query analysis
- **Container Network Interface**: Explore CNI options that preserve source IPs

## Configuration Files Modified

### 1. nftables.conf.j2
```bash
# Working MASQUERADE configuration
chain postrouting {
  type nat hook postrouting priority 100;
  oif "wg0" masquerade
}

# Attempted selective SNAT (non-working)
# oif "wg0" ip saddr != @rfc1918 udp dport 31053 snat to 10.172.90.2
```

### 2. edge_gateway defaults
```yaml
# Fixed circular dependency
edge_gateway_wg_peer_endpoint: "192.168.50.16:51820"  # was: "wg.kragh.dev:51820"
```

### 3. dnsdist configuration (experimental)
```lua
addLocal("0.0.0.0:53")
newServer("10.172.90.1:31053")
# Custom client IP logging attempted but connectivity issues prevented success
```

## Conclusion

**The MASQUERADE approach remains the best balance of reliability, simplicity, and maintainability** for this homelab DNS infrastructure. While client IP preservation in DNS logs would be nice-to-have, it's not worth the operational complexity and reliability risks.

Focus client IP preservation efforts on HTTP/HTTPS traffic where it has more business value and is architecturally easier to achieve.

---

*This analysis documents several hours of networking experimentation and serves as a reference for future DNS infrastructure decisions.*