# Cryptominer Scenario

This scenario simulates cryptocurrency mining malware to help security professionals learn detection and response techniques for resource hijacking attacks.

> ⚠️ **Safety Note**: This scenario runs in **SAFE MODE** by default, connecting only to an in-cluster sinkhole service with no actual mining.

## Overview

**MITRE ATT&CK Techniques:**
- [T1496 - Resource Hijacking](https://attack.mitre.org/techniques/T1496/)
- [T1055 - Process Injection](https://attack.mitre.org/techniques/T1055/)
- [T1059.004 - Unix Shell](https://attack.mitre.org/techniques/T1059/004/)

**Risk Level:** 🟩 Low (Safe mode with controlled simulation)

**Duration:** 10 minutes (auto-cleanup)

## What This Scenario Does

### Safe Mode (Default)
- Simulates XMRig cryptocurrency miner startup
- Connects to in-cluster sinkhole service instead of real mining pool
- Generates realistic process and network telemetry
- Uses minimal CPU resources (limited to 200m cores)
- Produces mining-like log output without actual computation

### Unsafe Mode (Experts Only)
- Can connect to real mining pools (user-configured)
- Higher resource usage allowed
- External network connections possible
- Requires explicit risk acknowledgment

## Quick Start

```bash
# Run the scenario (safe mode)
make run scenario=cryptominer

# View real-time logs
make logs scenario=cryptominer

# Check resource usage
kubectl top pods -n cdr-lab

# Clean up
make cleanup scenario=cryptominer
```

## Expected Telemetry

### Process Indicators
- Process name: `xmrig`, `sh`, or container runtime
- Command line: Contains mining-related arguments
- High CPU usage patterns (limited in safe mode)
- Network connections to mining pool addresses

### Network Indicators  
- Outbound TCP connections on port 3333 (typical mining pool port)
- Destination: `sinkhole.cdr-lab.svc.cluster.local` (safe mode)
- Persistent long-lived connections
- Periodic keep-alive traffic

### Log Patterns
```
Starting CDR Lab Cryptominer Simulation
Mode: Safe (connecting to sinkhole service)  
Pool: sinkhole.cdr-lab.svc.cluster.local:3333
Mining simulation active - round 42
  -> Simulated hash rate: 73 H/s
  -> Pool difficulty: 847291
  -> Shares: accepted=2, rejected=0
```

### Resource Metrics
- CPU usage: Steady moderate consumption
- Memory usage: ~128-256MB
- Network throughput: Low but consistent
- Container restart count: Should remain 0

## Detection Opportunities

### SIEM/XDR Queries

**Splunk:**
```spl
index=kubernetes source="*cdr-lab*"
| search "xmrig" OR "mining" OR "pool" OR "hash rate"
| stats count by host, container_name, message
```

**Elastic (KQL):**
```kql
kubernetes.namespace:"cdr-lab" AND 
(message:*mining* OR message:*xmrig* OR message:*pool*)
```

**Microsoft Sentinel:**
```kql
KubePodInventory
| where Namespace == "cdr-lab"
| where ContainerName contains "miner"
| extend ProcessName = extract(@"Starting ([^\\s]+)", 1, PodLabel_s)
```

### Resource-Based Detection
```bash
# Find pods with sustained CPU usage
kubectl top pods -n cdr-lab --sort-by=cpu

# Monitor network connections
kubectl exec -n cdr-lab deployment/cryptominer-job -- netstat -an

# Check for mining-related processes
kubectl exec -n cdr-lab deployment/cryptominer-job -- ps aux | grep -i mine
```

### Network Detection
```yaml
# NetworkPolicy to detect mining traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: detect-mining-traffic
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: cryptominer
  policyTypes:
  - Egress
  egress:
  - to: []
    ports:
    - protocol: TCP
      port: 3333  # Common mining port
    - protocol: TCP  
      port: 4444  # Alternative mining port
```

## Response Playbook

### 1. Initial Detection
```bash
# Identify suspicious pods
kubectl get pods -n cdr-lab -l cdr-lab/scenario-id=cryptominer

# Check resource consumption
kubectl top pods -n cdr-lab --sort-by=cpu

# Review recent events
kubectl get events -n cdr-lab --sort-by=.metadata.creationTimestamp
```

### 2. Investigation
```bash
# Examine pod details
kubectl describe pod -n cdr-lab -l cdr-lab/scenario-id=cryptominer

# Check container logs
kubectl logs -f -n cdr-lab -l cdr-lab/scenario-id=cryptominer

# Inspect network connections
kubectl exec -n cdr-lab deployment/cryptominer-job -- netstat -an | grep 3333

# Review environment variables
kubectl exec -n cdr-lab deployment/cryptominer-job -- env | grep -i pool
```

### 3. Containment
```bash
# Scale down the deployment
kubectl scale deployment cryptominer-job --replicas=0 -n cdr-lab

# Block network access (if real threat)
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-cryptominer
  namespace: cdr-lab
spec:
  podSelector:
    matchLabels:
      cdr-lab/scenario-id: cryptominer
  policyTypes:
  - Ingress
  - Egress
  egress: []
  ingress: []
EOF
```

### 4. Eradication
```bash
# Remove the malicious workload
kubectl delete job cryptominer-job -n cdr-lab

# Clean up associated resources
kubectl delete configmap cryptominer-safe-config -n cdr-lab

# Verify removal
kubectl get all -n cdr-lab -l cdr-lab/scenario-id=cryptominer
```

## Scenario Variants

### Basic (Default)
Simple XMRig simulation with standard configuration:
```bash
make run scenario=cryptominer
```

### Advanced (Future)
Multi-stage deployment with persistence mechanisms:
```bash
# Coming in v1.1
make run scenario=cryptominer variant=advanced
```

### Stealth (Unsafe Mode Only)
Includes process hiding and anti-detection techniques:
```bash
# Requires unsafe mode and isolated environment
LAB_MODE=unsafe make run scenario=cryptominer variant=stealth
```

## Threat Intelligence Context

### Real-World Examples
- **Rocke Group**: Used XMRig for Monero mining in cloud environments
- **TeamTNT**: Deployed cryptominers in Kubernetes clusters
- **Kinsing**: Combined credential theft with mining operations

### Common Mining Pools
- `pool.supportxmr.com:3333` (Monero)
- `xmr-eu1.nanopool.org:14433` (Monero)
- `mine.moneropool.com:3333` (Monero)

### Wallet Addresses (Indicators)
The scenario uses a test wallet address:
`44AFFq5kSiGBoZ4NMDwYtN18obc8AemS33DBLWs3H7otXft3XjrpDtQGv7SqSsaBYBb98uNbr2VBBEt7f2wfn3RVGQBEP3A`

In real incidents, track wallet addresses for attribution and impact assessment.

## Configuration

### Environment Variables
- `POOL_ADDRESS`: Mining pool URL (sinkhole in safe mode)
- `WALLET_ADDRESS`: Cryptocurrency wallet address
- `WORKER_NAME`: Identifier for the mining worker
- `THREADS`: Number of mining threads (1 in safe mode)
- `SAFE_MODE`: Controls simulation vs real mining

### Resource Limits
```yaml
resources:
  limits:
    memory: "256Mi"
    cpu: "200m"    # Limited in safe mode
  requests:
    memory: "128Mi"
    cpu: "100m"
```

### Network Configuration
Safe mode connections:
- **Pool**: `sinkhole.cdr-lab.svc.cluster.local:3333`
- **Protocol**: TCP
- **TLS**: Disabled for simplicity

## Troubleshooting

### Scenario Won't Start
```bash
# Check resource availability
kubectl describe nodes

# Verify namespace exists
kubectl get namespace cdr-lab

# Check image availability
docker pull metal3d/xmrig:latest
```

### No Network Connections
```bash
# Verify sinkhole service is running
kubectl get svc sinkhole -n cdr-lab

# Check network policies
kubectl get networkpolicy -n cdr-lab

# Test connectivity
kubectl exec -n cdr-lab -it deployment/sinkhole -- nc -zv sinkhole 3333
```

### High Resource Usage
```bash
# Check current limits
kubectl describe pod -n cdr-lab -l cdr-lab/scenario-id=cryptominer

# Monitor resource usage
watch kubectl top pods -n cdr-lab

# Adjust limits if needed (safe mode)
kubectl patch job cryptominer-job -n cdr-lab --patch '
spec:
  template:
    spec:
      containers:
      - name: miner
        resources:
          limits:
            cpu: "100m"'
```

## Learning Objectives

After completing this scenario, you should understand:

1. **How cryptocurrency miners operate** in container environments
2. **Network indicators** of mining activity  
3. **Resource consumption patterns** typical of cryptominers
4. **Detection techniques** using logs, metrics, and network monitoring
5. **Response procedures** for containing and eradicating miners
6. **Prevention strategies** using network policies and resource limits

## Next Steps

- Try the **Container Escape** scenario to see how miners might be deployed
- Explore the **SUID** scenario to understand privilege escalation
- Set up **real-time monitoring** using your SIEM/XDR platform
- Create **custom detection rules** based on the telemetry observed

## References

- [MITRE ATT&CK - Resource Hijacking (T1496)](https://attack.mitre.org/techniques/T1496/)
- [Palo Alto Unit 42 - Rocke Group Analysis](https://unit42.paloaltonetworks.com/malware-used-by-rocke-group/)
- [CrowdStrike - Cryptojacking Evolution](https://www.crowdstrike.com/blog/cryptojacking-continues-to-evolve/)
- [XMRig Documentation](https://xmrig.com/docs)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
