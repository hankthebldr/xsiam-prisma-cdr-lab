# Quick Start Guide

Get up and running with the XSIAM Prisma CDR Lab in minutes.

> ⚠️ **Safety First**: This lab runs in **SAFE MODE** by default with simulated attacks.

## Prerequisites

- Docker installed and running
- kubectl configured  
- 4GB+ available RAM
- 2+ CPU cores

## 5-Minute Setup

### 1. Install Dependencies

**macOS (Homebrew):**
```bash
# Install required tools
brew install kind kubectl
```

**Linux:**
```bash
# Install kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

**Windows (Chocolatey):**
```powershell
choco install kind kubernetes-cli
```

### 2. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/your-org/xsiam-prisma-cdr-lab.git
cd xsiam-prisma-cdr-lab

# Verify dependencies
make bootstrap
```

### 3. Create Lab Cluster

```bash
# Create KinD cluster (takes 2-3 minutes)
make kind-up
```

This creates:
- 3-node Kubernetes cluster
- Security monitoring setup
- Sinkhole services for safe scenarios
- Network policies and pod security

### 4. Run Your First Scenario

```bash
# List available scenarios
make list

# Run cryptominer simulation (safe mode)
make run scenario=cryptominer

# View real-time logs
make logs scenario=cryptominer
```

### 5. Explore and Clean Up

```bash
# Check scenario status
make status

# View cluster resources
kubectl get pods -n cdr-lab

# Clean up scenario
make cleanup scenario=cryptominer

# Tear down cluster when done
make kind-down
```

## What Just Happened?

1. **Safe Simulation**: The cryptominer connected to an in-cluster sinkhole (not a real mining pool)
2. **Resource Monitoring**: CPU and memory usage is tracked and limited
3. **Network Isolation**: All traffic stays within the cluster
4. **Audit Logging**: All activities are logged for analysis
5. **Automatic Cleanup**: Resources are cleaned up after 10 minutes

## Next Steps

### Try More Scenarios

```bash
# SUID privilege escalation (safe mode)
make run scenario=suid

# Container escape techniques (safe mode)  
make run scenario=container-escape

# Vulnerable web application
make run scenario=juice-shop
```

### Monitor and Analyze

```bash
# View all running scenarios
kubectl get pods -n cdr-lab -l cdr-lab/scenario-id

# Check resource usage
kubectl top pods -n cdr-lab

# View network policies
kubectl get networkpolicies -n cdr-lab

# Access cluster metrics
kubectl top nodes
```

### Debug and Troubleshoot

```bash
# Show debug information
make debug

# View all logs
make logs-all

# Open debug shell
make shell

# Check cluster health
kubectl get nodes -o wide
```

## Common Workflows

### Security Analyst Workflow

```bash
# 1. Start scenario
make run scenario=cryptominer

# 2. Collect telemetry 
kubectl logs -f -n cdr-lab -l cdr-lab/scenario-id=cryptominer

# 3. Analyze with your SIEM/XDR
# - Export logs to Splunk/Elastic
# - Create detection rules
# - Test alerting

# 4. Clean up
make cleanup scenario=cryptominer
```

### Red Team Training

```bash
# Start with safe mode
make run scenario=container-escape mode=safe

# Review techniques used
make logs scenario=container-escape

# Try unsafe mode (isolated environment only!)
LAB_MODE=unsafe make run scenario=container-escape
# Type: I_ACKNOWLEDGE_THE_RISK
```

### Detection Engineering

```bash
# Run scenario
make run scenario=suid

# Export detection data
kubectl logs -n cdr-lab -l cdr-lab/scenario-id=suid --since=1h > suid-logs.txt

# Create detection rules using the sample queries in docs/DETECTIONS.md
```

## Safety Reminders

✅ **Safe Practices:**
- Default safe mode simulates attacks
- Network traffic goes to sinkholes
- Resource limits prevent system impact
- Automatic cleanup after completion

⚠️ **Unsafe Mode (Experts Only):**
- Only in completely isolated environments
- Requires explicit confirmation
- May generate real network traffic
- Manual cleanup required

## Troubleshooting

### Cluster Won't Start
```bash
# Check Docker is running
docker ps

# Clean up any existing clusters
make kind-down
docker system prune -f

# Try again
make kind-up
```

### Scenario Won't Run
```bash
# Check cluster status
make debug

# Verify namespace
kubectl get ns cdr-lab

# Check for resource constraints
kubectl describe pods -n cdr-lab
```

### Need Help?

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
2. Review [SAFETY.md](SAFETY.md) for safety guidelines
3. See [SCENARIOS.md](SCENARIOS.md) for detailed scenario documentation
4. Open an issue on GitHub with:
   - Output of `make debug`
   - Steps to reproduce
   - Expected vs actual behavior

## Learning Resources

- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Container Security Guide](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Network Policy Recipes](https://github.com/ahmetb/kubernetes-network-policy-recipes)

---

**Ready to dive deeper?** Check out the full [README.md](../README.md) and explore individual scenarios!
