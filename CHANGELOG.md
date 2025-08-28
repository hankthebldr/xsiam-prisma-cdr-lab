# Changelog

All notable changes to the XSIAM Prisma CDR Lab will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-XX-XX

### 🚀 Major Refactoring and Safety Framework

This release represents a complete overhaul of the CDR Lab with a focus on safety, maintainability, and professional-grade tooling.

### Added

#### Safety Framework
- **Safe-by-default mode** for all scenarios with simulated attacks
- **Typed safety confirmations** for unsafe operations (`I_ACKNOWLEDGE_THE_RISK`)
- **Network isolation** with default-deny policies and in-cluster sinkholes
- **Resource limits and security contexts** on all workloads
- **Pod Security Standards** enforcement in the lab namespace
- **Automatic cleanup** with TTL-based job termination

#### Infrastructure and Tooling
- **Comprehensive Makefile** with 30+ targets for common operations
- **KinD cluster automation** with optimized security configuration
- **Centralized script library** (`scripts/common.sh`) with error handling
- **Scenario runner** (`scripts/run-scenario.sh`) with safety gates
- **Cleanup automation** (`scripts/cleanup.sh`) with verification
- **Pre-commit hooks** for code quality and safety validation

#### Documentation
- **Comprehensive safety guidelines** (`docs/SAFETY.md`)
- **Quick start guide** (`docs/QUICKSTART.md`) for 5-minute setup
- **Detailed scenario documentation** with detection examples
- **Complete README** with architecture overview and safety warnings

#### Kustomize Framework  
- **Base and overlay structure** for scenario configuration
- **Safe overlay** with hardened security contexts and network policies
- **Unsafe overlay** (future) with explicit privilege escalation
- **Common labels and annotations** across all resources
- **Resource transformations** for consistent security hardening

#### CI/CD and Quality
- **GitHub Actions CI** with linting, validation, security scanning, and testing
- **Multi-scenario testing matrix** with KinD cluster automation
- **Security scanning** with Trivy and secret detection
- **Documentation validation** and metadata consistency checks
- **Automated safety checks** preventing accidental unsafe deployments

### Enhanced Scenarios

#### Cryptominer Scenario
- **Complete rewrite** with safe-mode simulation
- **Detailed metadata** including MITRE ATT&CK mapping and threat intelligence
- **Comprehensive README** with detection queries and response playbooks
- **Realistic telemetry generation** without actual mining
- **Resource-limited execution** preventing system impact
- **Automatic cleanup** after 10 minutes

#### Infrastructure Components
- **In-cluster sinkhole services** for safe network simulation
- **Metrics server integration** for resource monitoring
- **Audit logging configuration** for security event tracking
- **Network policy enforcement** with granular traffic control

### Changed

#### Repository Structure
- **Reorganized directory layout** with logical separation of concerns
- **Moved legacy files** from `1.0/` and `1.1/` to new structure
- **Standardized naming** fixing typos and inconsistencies
- **Centralized configuration** in `overlays/` and `policies/`

#### Safety Model
- **Changed default behavior** from unsafe to safe mode
- **Explicit opt-in required** for any potentially harmful operations
- **Network traffic containment** within cluster boundaries
- **Resource consumption limits** preventing exhaustion attacks

### Deprecated

#### Legacy Structure
- **Old directory structure** (`1.0/`, `1.1/`) deprecated in favor of `scenarios/`
- **Direct manifest execution** deprecated in favor of Kustomize-based deployment
- **Unsafe-first approach** replaced with safe-by-default design

### Security Improvements

#### Kubernetes Security
- **Pod Security Standards** baseline enforcement with restricted audit
- **Network policies** with default-deny egress and explicit allow lists
- **Security contexts** with non-root execution and dropped capabilities
- **Resource limits** preventing resource exhaustion attacks
- **Admission controllers** (future) with OPA Gatekeeper policies

#### Development Security  
- **Secret scanning** in CI with baseline management
- **Vulnerability scanning** of container images and IaC
- **Pre-commit validation** of safety configurations
- **Automated security checks** in pull requests

### Technical Debt Resolution

#### Code Quality
- **Shell script linting** with ShellCheck and consistent error handling
- **YAML validation** with yamllint and Kubernetes dry-run checks
- **Markdown linting** for documentation consistency
- **Typo checking** across all text files

#### Maintainability
- **Modular architecture** with reusable components
- **Configuration management** with environment variable support
- **Comprehensive testing** with scenario validation
- **Documentation generation** (future) from metadata

## [1.1.0] - Previous Release

### Added
- Attack scenarios directory structure
- OWASP Juice Shop integration
- Additional TTP documentation
- Container escape techniques

### Changed
- Expanded scenario coverage
- Improved attack technique examples

## [1.0.0] - Initial Release

### Added
- Basic CDR lab structure
- SUID attack simulation
- Cryptominer container examples
- Malicious container scenarios
- Initial documentation

---

## Migration Guide

### From v1.x to v2.0

#### For Users
1. **Update commands**: Use `make` targets instead of direct kubectl
   ```bash
   # Old: kubectl apply -f 1.0/cryptominers-container/xmrig.yaml
   # New: make run scenario=cryptominer
   ```

2. **Safety confirmation**: Unsafe operations now require explicit confirmation
   ```bash
   # This will prompt for safety confirmation:
   LAB_MODE=unsafe make run scenario=container-escape
   ```

3. **Cluster setup**: Use automated KinD setup
   ```bash
   # New approach:
   make kind-up
   make run scenario=cryptominer
   make kind-down
   ```

#### For Developers
1. **Use new structure**: Scenarios go in `scenarios/v1.0/<name>/`
2. **Include metadata**: Every scenario needs `metadata.yaml`
3. **Follow safety model**: Default to safe mode, explicit unsafe mode
4. **Use Kustomize**: Base manifests with overlay transformations
5. **Add documentation**: Include README.md with detection examples

#### Breaking Changes
- **Command interface**: Direct kubectl commands replaced with make targets
- **File paths**: Scenarios moved from `1.0/` to `scenarios/v1.0/`
- **Safety model**: Unsafe operations require explicit confirmation
- **Network behavior**: Default deny egress with sinkhole connections

#### Compatibility
- **Legacy files**: Still available but deprecated
- **Migration period**: v1.x structure supported until v2.1
- **Documentation**: Includes mapping from old to new paths

---

## Contributing

When contributing new scenarios or features:

1. **Follow safety model**: Safe by default, unsafe opt-in
2. **Include metadata**: Complete `metadata.yaml` with MITRE mapping
3. **Write documentation**: Detailed README with detection examples
4. **Add tests**: Scenario validation and safety checks
5. **Update changelog**: Document all changes

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for detailed guidelines.
