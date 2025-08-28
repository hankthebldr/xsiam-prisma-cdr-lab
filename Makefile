# XSIAM Prisma CDR Lab Makefile
# Provides convenient targets for common operations

# Configuration
SHELL := /bin/bash
.DEFAULT_GOAL := help
.PHONY: help bootstrap kind-up kind-down run cleanup cleanup-all logs list lint test validate

# Variables
PROJECT_ROOT := $(shell pwd)
CLUSTER_NAME ?= cdr-lab
NAMESPACE ?= cdr-lab
LAB_MODE ?= safe
SCENARIO ?= 
VERSION ?= $(shell cat VERSION 2>/dev/null || echo "dev")

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

##@ General

help: ## Display this help message
	@echo "XSIAM Prisma CDR Lab - Kubernetes Security Training Environment"
	@echo ""
	@echo "$(YELLOW)⚠️  SAFETY WARNING ⚠️$(NC)"
	@echo "This lab contains simulated attack scenarios for educational purposes only."
	@echo "Never run in production environments. Safe mode is default."
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make $(BLUE)<target>$(NC)\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(BLUE)%-15s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(YELLOW)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

bootstrap: ## Install required tools and dependencies
	@echo "$(BLUE)Installing dependencies...$(NC)"
	@command -v kind >/dev/null || (echo "$(RED)Please install kind: https://kind.sigs.k8s.io/$(NC)" && exit 1)
	@command -v kubectl >/dev/null || (echo "$(RED)Please install kubectl$(NC)" && exit 1)
	@command -v docker >/dev/null || (echo "$(RED)Please install docker$(NC)" && exit 1)
	@echo "$(GREEN)✓ All dependencies are installed$(NC)"
	@echo ""
	@echo "Optional tools:"
	@echo "  - pre-commit: pip install pre-commit && pre-commit install"
	@echo "  - yamllint: pip install yamllint"
	@echo "  - shellcheck: brew install shellcheck"

version: ## Show current version
	@echo "CDR Lab Version: $(VERSION)"

##@ Cluster Management

kind-up: ## Create a KinD cluster for the lab
	@echo "$(BLUE)Creating KinD cluster '$(CLUSTER_NAME)'...$(NC)"
	@hack/kind-up.sh --name $(CLUSTER_NAME)

kind-down: ## Delete the KinD cluster
	@echo "$(BLUE)Deleting KinD cluster '$(CLUSTER_NAME)'...$(NC)"
	@hack/kind-down.sh --name $(CLUSTER_NAME)

kind-status: ## Show KinD cluster status
	@echo "$(BLUE)Checking cluster status...$(NC)"
	@kubectl cluster-info 2>/dev/null || echo "$(YELLOW)No cluster found. Run 'make kind-up' first.$(NC)"
	@kubectl get nodes 2>/dev/null || true

##@ Scenario Management

run: ## Run a scenario (usage: make run scenario=cryptominer [mode=safe|unsafe])
	@if [ -z "$(SCENARIO)" ]; then \
		echo "$(RED)Error: scenario parameter required$(NC)"; \
		echo "Usage: make run scenario=<scenario_id> [mode=safe|unsafe]"; \
		echo ""; \
		echo "Available scenarios:"; \
		$(MAKE) list; \
		exit 1; \
	fi
	@echo "$(BLUE)Running scenario '$(SCENARIO)' in $(LAB_MODE) mode...$(NC)"
	@LAB_MODE=$(LAB_MODE) scripts/run-scenario.sh $(SCENARIO) $(LAB_MODE)

cleanup: ## Clean up a scenario (usage: make cleanup scenario=cryptominer)
	@if [ -z "$(SCENARIO)" ]; then \
		echo "$(RED)Error: scenario parameter required$(NC)"; \
		echo "Usage: make cleanup scenario=<scenario_id>"; \
		echo "Or: make cleanup-all"; \
		exit 1; \
	fi
	@echo "$(BLUE)Cleaning up scenario '$(SCENARIO)'...$(NC)"
	@scripts/cleanup.sh $(SCENARIO)

cleanup-all: ## Clean up all scenarios and the lab namespace
	@echo "$(YELLOW)This will delete ALL scenarios and the $(NAMESPACE) namespace$(NC)"
	@read -p "Continue? [y/N] " -n 1 -r; echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		scripts/cleanup.sh all; \
	else \
		echo "Cancelled"; \
	fi

list: ## List all available scenarios
	@echo "$(BLUE)Available scenarios:$(NC)"
	@if [ -d scenarios/v1.0 ]; then \
		for dir in scenarios/v1.0/*/; do \
			if [ -d "$$dir" ]; then \
				scenario=$$(basename "$$dir"); \
				if [ -f "$$dir/metadata.yaml" ]; then \
					name=$$(grep "^name:" "$$dir/metadata.yaml" | cut -d':' -f2- | sed 's/^[[:space:]]*//'); \
					risk=$$(grep "^risk:" "$$dir/metadata.yaml" | cut -d':' -f2- | sed 's/^[[:space:]]*//'); \
					printf "  %-15s %s (risk: %s)\n" "$$scenario" "$$name" "$$risk"; \
				else \
					printf "  %-15s %s\n" "$$scenario" "(no metadata)"; \
				fi \
			fi \
		done \
	else \
		echo "  No scenarios found"; \
	fi
	@echo ""
	@echo "Usage: make run scenario=<scenario_id> [mode=safe|unsafe]"

status: ## Show status of running scenarios
	@echo "$(BLUE)Scenario Status:$(NC)"
	@kubectl get pods -n $(NAMESPACE) -l cdr-lab/scenario-id --no-headers 2>/dev/null | \
		awk '{print "  " $$1 " (" $$3 ")"}' || echo "  No scenarios running"

logs: ## View logs for a scenario (usage: make logs scenario=cryptominer)
	@if [ -z "$(SCENARIO)" ]; then \
		echo "$(RED)Error: scenario parameter required$(NC)"; \
		echo "Usage: make logs scenario=<scenario_id>"; \
		exit 1; \
	fi
	@echo "$(BLUE)Viewing logs for scenario '$(SCENARIO)'...$(NC)"
	@kubectl logs -f -n $(NAMESPACE) -l cdr-lab/scenario-id=$(SCENARIO) --all-containers=true

##@ Development

lint: ## Run linting on all files
	@echo "$(BLUE)Running linters...$(NC)"
	@echo "Checking shell scripts..."
	@if command -v shellcheck >/dev/null; then \
		find scripts hack -name "*.sh" -exec shellcheck {} +; \
	else \
		echo "$(YELLOW)shellcheck not found, skipping$(NC)"; \
	fi
	@echo "Checking YAML files..."
	@if command -v yamllint >/dev/null; then \
		yamllint scenarios/ overlays/ policies/ .github/ || true; \
	else \
		echo "$(YELLOW)yamllint not found, skipping$(NC)"; \
	fi
	@echo "Checking Markdown files..."
	@if command -v markdownlint >/dev/null; then \
		markdownlint docs/ README.md || true; \
	else \
		echo "$(YELLOW)markdownlint not found, skipping$(NC)"; \
	fi
	@echo "$(GREEN)✓ Linting complete$(NC)"

validate: ## Validate Kubernetes manifests
	@echo "$(BLUE)Validating Kubernetes manifests...$(NC)"
	@for scenario in scenarios/v1.0/*/; do \
		if [ -f "$$scenario/kustomization.yaml" ]; then \
			scenario_name=$$(basename "$$scenario"); \
			echo "Validating $$scenario_name..."; \
			kubectl kustomize "$$scenario" | kubectl apply --dry-run=client -f - >/dev/null || \
				echo "$(YELLOW)Warning: validation failed for $$scenario_name$(NC)"; \
		fi \
	done
	@echo "$(GREEN)✓ Validation complete$(NC)"

test: ## Run tests
	@echo "$(BLUE)Running tests...$(NC)"
	@if [ -f tests/run-tests.sh ]; then \
		tests/run-tests.sh; \
	else \
		echo "$(YELLOW)No tests found$(NC)"; \
	fi

format: ## Format code and configuration files
	@echo "$(BLUE)Formatting files...$(NC)"
	@find scripts hack -name "*.sh" -exec shfmt -w {} + 2>/dev/null || echo "$(YELLOW)shfmt not found, skipping shell formatting$(NC)"
	@echo "$(GREEN)✓ Formatting complete$(NC)"

##@ Documentation

docs: ## Generate documentation
	@echo "$(BLUE)Generating documentation...$(NC)"
	@if [ -f scripts/generate-docs.sh ]; then \
		scripts/generate-docs.sh; \
	else \
		echo "$(YELLOW)Documentation generator not found$(NC)"; \
	fi

serve-docs: ## Serve documentation locally
	@echo "$(BLUE)Serving documentation at http://localhost:8000$(NC)"
	@if command -v python3 >/dev/null; then \
		cd docs && python3 -m http.server 8000; \
	else \
		echo "$(RED)Python3 required to serve docs$(NC)"; \
	fi

##@ Security

security-scan: ## Run security scans on the codebase
	@echo "$(BLUE)Running security scans...$(NC)"
	@if command -v trivy >/dev/null; then \
		trivy fs --security-checks vuln,secret,config .; \
	else \
		echo "$(YELLOW)trivy not found, install from: https://trivy.dev/$(NC)"; \
	fi

policy-test: ## Test security policies
	@echo "$(BLUE)Testing security policies...$(NC)"
	@if [ -d policies/ ]; then \
		echo "Found policies directory"; \
		# Add policy testing logic here \
	else \
		echo "$(YELLOW)No policies directory found$(NC)"; \
	fi

##@ Debugging

debug: ## Show debug information
	@echo "$(BLUE)CDR Lab Debug Information$(NC)"
	@echo "Version: $(VERSION)"
	@echo "Project Root: $(PROJECT_ROOT)"
	@echo "Cluster: $(CLUSTER_NAME)"
	@echo "Namespace: $(NAMESPACE)"
	@echo "Lab Mode: $(LAB_MODE)"
	@echo ""
	@echo "Cluster Status:"
	@kubectl cluster-info 2>/dev/null || echo "No cluster connection"
	@echo ""
	@echo "Nodes:"
	@kubectl get nodes 2>/dev/null || echo "No nodes found"
	@echo ""
	@echo "Lab Namespace:"
	@kubectl get all -n $(NAMESPACE) 2>/dev/null || echo "Namespace $(NAMESPACE) not found"

shell: ## Open a debug shell in the lab namespace
	@echo "$(BLUE)Opening debug shell in $(NAMESPACE) namespace...$(NC)"
	@kubectl run debug-shell --rm -i --tty --image=busybox:latest -n $(NAMESPACE) -- /bin/sh

logs-all: ## View logs from all pods in the lab namespace
	@echo "$(BLUE)Viewing logs from all pods in $(NAMESPACE)...$(NC)"
	@kubectl logs -f -n $(NAMESPACE) --all-containers=true --selector="app.kubernetes.io/part-of=cdr-lab"

##@ CI/CD

ci: lint validate test ## Run all CI checks

install-pre-commit: ## Install pre-commit hooks
	@echo "$(BLUE)Installing pre-commit hooks...$(NC)"
	@if command -v pre-commit >/dev/null; then \
		pre-commit install; \
		echo "$(GREEN)✓ Pre-commit hooks installed$(NC)"; \
	else \
		echo "$(RED)pre-commit not found. Install with: pip install pre-commit$(NC)"; \
	fi

##@ Examples

examples: ## Show common usage examples
	@echo "$(BLUE)CDR Lab Usage Examples$(NC)"
	@echo ""
	@echo "$(YELLOW)Setup:$(NC)"
	@echo "  make bootstrap         # Install dependencies"
	@echo "  make kind-up          # Create cluster"
	@echo ""
	@echo "$(YELLOW)Run scenarios:$(NC)"
	@echo "  make list             # List available scenarios"
	@echo "  make run scenario=cryptominer"
	@echo "  make run scenario=suid mode=safe"
	@echo "  LAB_MODE=unsafe make run scenario=container-escape"
	@echo ""
	@echo "$(YELLOW)Monitor and debug:$(NC)"
	@echo "  make status           # Check scenario status"
	@echo "  make logs scenario=cryptominer"
	@echo "  make debug           # Show debug info"
	@echo ""
	@echo "$(YELLOW)Cleanup:$(NC)"
	@echo "  make cleanup scenario=cryptominer"
	@echo "  make cleanup-all     # Clean everything"
	@echo "  make kind-down       # Delete cluster"

##@ Advanced

dry-run: ## Run scenarios in dry-run mode (usage: make dry-run scenario=cryptominer)
	@if [ -z "$(SCENARIO)" ]; then \
		echo "$(RED)Error: scenario parameter required$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Dry run for scenario '$(SCENARIO)'...$(NC)"
	@DRY_RUN=true LAB_MODE=$(LAB_MODE) scripts/run-scenario.sh $(SCENARIO) $(LAB_MODE)

backup: ## Backup cluster state
	@echo "$(BLUE)Backing up cluster state...$(NC)"
	@mkdir -p backups
	@kubectl get all -n $(NAMESPACE) -o yaml > backups/cluster-state-$$(date +%Y%m%d-%H%M%S).yaml
	@echo "$(GREEN)✓ Backup saved to backups/$(NC)"

restore: ## Restore cluster state (usage: make restore file=backup.yaml)
	@if [ -z "$(file)" ]; then \
		echo "$(RED)Error: file parameter required$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)Restoring from $(file)...$(NC)"
	@kubectl apply -f $(file)

##@ Internal

_check-scenario:
	@if [ -z "$(SCENARIO)" ]; then \
		echo "$(RED)Error: SCENARIO variable not set$(NC)" >&2; \
		exit 1; \
	fi

_check-cluster:
	@kubectl cluster-info >/dev/null 2>&1 || \
		(echo "$(RED)Error: No cluster connection. Run 'make kind-up' first$(NC)" >&2 && exit 1)

.PHONY: _check-scenario _check-cluster
