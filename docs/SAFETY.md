# Safety Guidelines

> ⚠️ **CRITICAL SAFETY WARNING** ⚠️
>
> This lab contains attack simulation scenarios designed for **educational purposes only**.
> **NEVER run these scenarios in production environments** or on systems containing sensitive data.

## Safety Philosophy

The XSIAM Prisma CDR Lab operates on a **"Safe by Default"** principle:

- **All scenarios run in SAFE MODE by default** with simulated attacks
- **Unsafe mode requires explicit confirmation** and should only be used in isolated environments
- **Network traffic is contained** within the cluster or directed to sinkholes
- **Resource limits prevent resource exhaustion** attacks
- **Security policies prevent privilege escalation** unless explicitly allowed

## Safety Modes

### Safe Mode (Default)

Safe mode provides realistic attack simulations while maintaining safety:

✅ **What Safe Mode Does:**
- Logs attack actions without performing harmful operations
- Directs network traffic to in-cluster sinkholes
- Uses non-privileged containers with restricted capabilities
- Enforces resource limits and security contexts
- Mounts scratch filesystems instead of host paths
- Provides realistic telemetry for detection rule development

✅ **Safe Mode Guarantees:**
- No data will be corrupted or exfiltrated
- No persistent backdoors will be installed
- No network connections to external malicious infrastructure
- No privilege escalation to host systems
- No resource exhaustion attacks

### Unsafe Mode (Explicit Opt-in)

Unsafe mode allows more realistic attacks but requires extreme caution:

⚠️ **Unsafe Mode Warnings:**
- May use privileged containers with host access
- May generate real network connections to external systems
- May perform actual file system modifications
- May attempt real privilege escalation techniques
- Should **ONLY** be used in completely isolated lab environments

⚠️ **Required Confirmation:**
```bash
# Unsafe mode requires typing this exact confirmation:
I_ACKNOWLEDGE_THE_RISK
```

⚠️ **High-Risk Scenarios:**
High-risk scenarios in unsafe mode require additional confirmation:
```bash
EXTREME_RISK_ACCEPTED
```

## Environment Requirements

### Safe Environments ✅

These environments are appropriate for running the lab:

- **KinD clusters** on dedicated lab machines
- **Isolated VM environments** with no network access to production
- **Air-gapped development clusters**
- **Dedicated security training environments**
- **Container sandboxes** with resource limits

### Unsafe Environments ❌

**NEVER** run this lab in these environments:

- Production Kubernetes clusters
- Development clusters with access to production data
- Shared development environments
- Cloud clusters with production workloads
- Any system with sensitive data
- Corporate networks without explicit approval

## Network Safety

### Default Network Policies

All scenarios deploy with restrictive network policies:

```yaml
# Default deny egress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-egress
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress: []
```

### Sinkhole Services

Safe mode scenarios use in-cluster sinkhole services:

- **Cryptominer sinkhole**: Simulates mining pool at `sinkhole.cdr-lab.svc:3333`
- **C2 sinkhole**: Simulates command & control at `sinkhole.cdr-lab.svc:4444`
- **DNS sinkhole**: Captures and logs DNS requests
- **HTTP sinkhole**: Simulates malicious web servers

### Egress Allow Lists

When external network access is required (unsafe mode only):

- Connections are limited to specific IP addresses/domains
- All traffic is logged and monitored
- Time-limited connections with automatic cleanup

## Resource Safety

### Resource Limits

All scenarios include resource limits to prevent resource exhaustion:

```yaml
resources:
  limits:
    memory: "512Mi"
    cpu: "500m"
  requests:
    memory: "128Mi"
    cpu: "100m"
```

### Cleanup Guarantees

- **Automatic cleanup**: Jobs include `ttlSecondsAfterFinished`
- **Manual cleanup**: `make cleanup scenario=<name>` removes all resources
- **Force cleanup**: `make cleanup-all --force` removes everything
- **Backup and restore**: Cluster state is backed up before destructive operations

## Security Controls

### Pod Security Standards

The `cdr-lab` namespace enforces security controls:

```yaml
metadata:
  labels:
    # Baseline security by default
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### Required Labels

Unsafe scenarios require explicit labeling:

```yaml
metadata:
  labels:
    cdr-lab/allow-privileged: "true"    # Required for privileged containers
    cdr-lab/allow-host-network: "true"  # Required for host networking
    cdr-lab/allow-host-pid: "true"      # Required for host PID namespace
```

### Admission Controllers

OPA Gatekeeper policies enforce safety:

- Block privileged containers without explicit labels
- Enforce image digest pinning
- Require resource limits
- Block host path mounts in safe mode
- Enforce network policies

## Scenario-Specific Safety

### SUID Attack Scenario

**Safe Mode:**
- Creates temporary files in `emptyDir` volumes
- Logs SUID simulation without actual privilege escalation
- Uses `inotify` for file monitoring instead of `auditd`

**Unsafe Mode:**
- May mount host filesystem with restricted paths
- Requires privileged security context
- Limited to specific host directories

### Cryptominer Scenario

**Safe Mode:**
- Connects to in-cluster sinkhole service
- CPU usage limited to minimal levels
- No actual cryptocurrency mining

**Unsafe Mode:**
- May connect to real mining pools (user-configured)
- Requires explicit wallet configuration
- Network egress limited to specified pools

### Container Escape Scenario

**Safe Mode:**
- Simulates escape techniques with detailed logging
- No actual host access or modification
- Educational enumeration of attack vectors

**Unsafe Mode:**
- May perform real container escape attempts
- Requires privileged containers and host mounts
- Limited to specific capabilities and paths

### Reverse Shell Scenario

**Safe Mode:**
- Connects to in-cluster sinkhole service
- Simulates command execution with logging
- No actual remote access established

**Unsafe Mode:**
- May establish real reverse shell connections
- Limited to lab-controlled endpoints
- Time-limited with automatic termination

## Monitoring and Auditing

### Audit Logging

All lab activities are audited:

- Kubernetes API calls are logged
- Container actions are captured
- Network connections are monitored
- File system access is tracked

### Detection Examples

Sample detection rules are provided for:

- SIEM integration (Splunk, Elastic)
- XDR platforms (Cortex XDR, Sentinel)
- Cloud security (Prisma Cloud, Falco)
- Custom monitoring solutions

## Incident Response

### If Something Goes Wrong

1. **Immediately stop the scenario:**
   ```bash
   make cleanup scenario=<name>
   ```

2. **Check cluster status:**
   ```bash
   make debug
   kubectl get pods -A
   ```

3. **Review logs:**
   ```bash
   make logs scenario=<name>
   kubectl logs -n cdr-lab --all-containers=true
   ```

4. **Full cleanup if needed:**
   ```bash
   make cleanup-all --force
   make kind-down
   ```

### Emergency Cleanup

If the normal cleanup fails:

```bash
# Force delete namespace
kubectl delete namespace cdr-lab --force --grace-period=0

# Delete cluster entirely
kind delete cluster --name cdr-lab

# Clean Docker resources
docker system prune -a -f
```

## Compliance and Legal

### Educational Use Only

This lab is designed for:
- Security education and training
- Red team exercise preparation  
- Detection rule development
- Security tool testing

### Prohibited Uses

**DO NOT** use this lab for:
- Actual attacks against systems you don't own
- Testing against production environments
- Malicious activities of any kind
- Compliance testing without proper authorization

### Data Protection

- No sensitive data should be present in lab environments
- Use synthetic or anonymized data for testing
- Regular cleanup prevents data accumulation
- Audit logs may be retained for analysis

## Reporting Issues

### Security Vulnerabilities

If you discover a security issue with the lab itself:

1. **Do not** create a public issue
2. Email security@[domain] with details
3. Allow 90 days for response before disclosure
4. We will acknowledge and provide updates

### Safety Concerns

If you believe a scenario is unsafe or could cause harm:

1. Create an issue with the `safety` label
2. Provide detailed explanation of the concern
3. Suggest safer alternatives if possible
4. We will investigate and respond promptly

## Version History

- v1.0: Initial safety guidelines
- v1.1: Added network safety controls
- v1.2: Enhanced resource limits and cleanup
- v2.0: Complete safety framework with admission controllers

---

**Remember: When in doubt, use safe mode and isolated environments!**
