# XSIAM Prisma CDR Lab

> ⚠️ **CRITICAL SAFETY WARNING** ⚠️
> 
> This lab contains simulated attack scenarios designed for **controlled security training environments only**.
> **NEVER run this in production environments** or on systems containing sensitive data.
> 
> By default, all scenarios run in **SAFE MODE** with controlled simulations. Unsafe mode requires explicit confirmation.

## Overview

The XSIAM Prisma CDR (Container Detection and Response) Lab is a Kubernetes-based security training environment that provides hands-on experience with container security threats, detection techniques, and response procedures. It's designed for security professionals, DevSecOps engineers, and anyone interested in learning container security.

## Features

- 🛡️ **Safe by Default**: All scenarios run in safe mode with simulated attacks
- 🎯 **MITRE ATT&CK Mapped**: Scenarios mapped to MITRE techniques
- 🔒 **Network Isolated**: Default-deny network policies with explicit allow-lists
- 📊 **Detection Ready**: Includes sample detection queries and telemetry guidance
- 🚀 **Easy Setup**: One-command setup with KinD (Kubernetes in Docker)
- 📋 **Policy Enforced**: OPA Gatekeeper policies prevent accidental unsafe deployments

## Quick Start

### Prerequisites

- Docker
- kubectl
- KinD (Kubernetes in Docker)
- kustomize (optional, built into kubectl 1.14+)

### 1. Set up the lab cluster

```bash
make kind-up
```

### 2. Run your first scenario (safe mode)

```bash
make run scenario=cryptominer mode=safe
```

### 3. View logs and detection data

```bash
kubectl logs -n cdr-lab -l cdr-lab/scenario-id=cryptominer
```

### 4. Clean up

```bash
make cleanup scenario=cryptominer
```

## Architecture

```
xsiam-prisma-cdr-lab/
├── scenarios/           # Attack scenario definitions
│   ├── v1.0/           # Version 1.0 scenarios
│   │   ├── suid/       # SUID privilege escalation
│   │   ├── cryptominer/ # Cryptocurrency mining
│   │   ├── container-escape/ # Container breakout techniques
│   │   └── ...
│   └── v1.1/           # Version 1.1 scenarios
├── overlays/           # Kustomize overlays
│   ├── safe/          # Safe mode configurations
│   └── unsafe/        # Unsafe mode configurations  
├── policies/          # Security policies
├── scripts/           # Automation scripts
└── docs/             # Documentation
```

## Available Scenarios

| Scenario | MITRE Techniques | Risk Level | Description |
|----------|------------------|------------|-------------|
| [SUID](scenarios/v1.0/suid/) | T1548.001 | 🟨 Medium | Setuid binary privilege escalation |
| [Cryptominer](scenarios/v1.0/cryptominer/) | T1496 | 🟩 Low | Cryptocurrency mining simulation |
| [Container Escape](scenarios/v1.0/container-escape/) | T1611 | 🟥 High | Container breakout techniques |
| [Reverse Shell](scenarios/v1.0/reverse-shell/) | T1059 | 🟨 Medium | Command and control via reverse shell |
| [Juice Shop](scenarios/v1.0/juice-shop/) | Various | 🟩 Low | OWASP vulnerable web application |

See [docs/SCENARIOS.md](docs/SCENARIOS.md) for complete details.

## Safety Model

### Safe Mode (Default)
- ✅ Simulated attacks that log actions without harmful effects
- ✅ Network traffic directed to in-cluster sinkholes
- ✅ Non-privileged containers with restricted capabilities
- ✅ Resource limits and security contexts enforced
- ✅ Read-only root filesystems where possible

### Unsafe Mode (Explicit Opt-in)
- ⚠️ Requires typing `I_ACKNOWLEDGE_THE_RISK`
- ⚠️ May use privileged containers and host mounts
- ⚠️ May generate real network traffic
- ⚠️ Should only be used in isolated lab environments

## Common Commands

```bash
# List available scenarios
make list

# Run a scenario in safe mode (default)
make run scenario=suid

# Run a scenario in unsafe mode (with confirmation)
make run scenario=suid mode=unsafe

# View scenario logs
make logs scenario=suid

# Clean up a scenario
make cleanup scenario=suid

# Clean up everything
make cleanup-all

# Set up development environment
make bootstrap

# Run tests
make test

# Lint code
make lint
```

## Development

See [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md) for development guidelines.

## Security

This lab is designed for **educational purposes only**. See [docs/SECURITY.md](docs/SECURITY.md) for security considerations and responsible disclosure.

## Documentation

- [Quick Start Guide](docs/QUICKSTART.md)
- [Safety Guidelines](docs/SAFETY.md)
- [Scenario Catalog](docs/SCENARIOS.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Detection Queries](docs/DETECTIONS.md)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Disclaimer

This software is provided "as is" for educational purposes only. Users are responsible for ensuring compliance with all applicable laws and regulations. The authors assume no responsibility for misuse of this software.
