#!/usr/bin/env bash
# Common utilities for CDR Lab scripts
# Source this file in other scripts: source scripts/common.sh

set -Eeuo pipefail
IFS=$'\n\t'

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LAB_MODE="${LAB_MODE:-safe}"
NAMESPACE="${NAMESPACE:-cdr-lab}"
LOG_LEVEL="${LOG_LEVEL:-info}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_json() {
    local level="$1"
    local message="$2"
    local scenario="${SCENARIO_ID:-unknown}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    cat << EOF
{"timestamp":"${timestamp}","level":"${level}","scenario":"${scenario}","message":"${message}"}
EOF
}

log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} ${message}" >&2
    log_json "info" "${message}"
}

log_warn() {
    local message="$1"
    echo -e "${YELLOW}[WARN]${NC} ${message}" >&2
    log_json "warn" "${message}"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} ${message}" >&2
    log_json "error" "${message}"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} ${message}" >&2
    log_json "info" "${message}"
}

log_debug() {
    local message="$1"
    if [[ "${LOG_LEVEL}" == "debug" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} ${message}" >&2
        log_json "debug" "${message}"
    fi
}

# Error handling
cleanup_on_exit() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Script exited with code ${exit_code}"
    fi
}

cleanup_on_error() {
    local line_number=$1
    log_error "Error occurred on line ${line_number}"
    log_error "Command: ${BASH_COMMAND}"
}

cleanup_on_interrupt() {
    log_warn "Script interrupted by user"
    exit 130
}

# Set up trap handlers
trap cleanup_on_exit EXIT
trap 'cleanup_on_error ${LINENO}' ERR
trap cleanup_on_interrupt INT

# Safety confirmation for unsafe operations
require_confirm() {
    local operation="$1"
    local required_text="I_ACKNOWLEDGE_THE_RISK"
    
    if [[ "${LAB_MODE}" != "unsafe" ]]; then
        log_info "Operation '${operation}' requires unsafe mode. Set LAB_MODE=unsafe"
        return 1
    fi
    
    log_warn "You are about to perform an unsafe operation: ${operation}"
    log_warn "This should only be done in isolated lab environments"
    log_warn "Type '${required_text}' to continue:"
    
    read -r user_input
    
    if [[ "${user_input}" != "${required_text}" ]]; then
        log_error "Confirmation failed. Operation cancelled."
        return 1
    fi
    
    log_warn "Unsafe operation confirmed. Proceeding..."
    return 0
}

# Utility functions
check_prerequisites() {
    local missing_tools=()
    
    for tool in kubectl docker kind kustomize; do
        if ! command -v "${tool}" &> /dev/null; then
            case "${tool}" in
                kustomize)
                    # kustomize is built into kubectl 1.14+, check version
                    if kubectl version --client --short 2>/dev/null | grep -q "v1\.[0-9][4-9]\|v1\.[2-9][0-9]"; then
                        log_debug "kustomize available via kubectl"
                        continue
                    fi
                    ;;
            esac
            missing_tools+=("${tool}")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        log_info "Please install the missing tools and try again"
        return 1
    fi
}

# Kubernetes utilities
wait_for_namespace() {
    local ns="$1"
    local timeout="${2:-60}"
    
    log_info "Waiting for namespace '${ns}' to be ready..."
    
    if ! kubectl get namespace "${ns}" &>/dev/null; then
        log_error "Namespace '${ns}' does not exist"
        return 1
    fi
    
    # Wait for namespace to be active
    local count=0
    while [[ $count -lt $timeout ]]; do
        if kubectl get namespace "${ns}" -o jsonpath='{.status.phase}' | grep -q "Active"; then
            log_success "Namespace '${ns}' is ready"
            return 0
        fi
        sleep 1
        ((count++))
    done
    
    log_error "Timeout waiting for namespace '${ns}' to be ready"
    return 1
}

wait_for_pods() {
    local selector="$1"
    local namespace="${2:-${NAMESPACE}}"
    local timeout="${3:-120}"
    
    log_info "Waiting for pods with selector '${selector}' in namespace '${namespace}'..."
    
    if ! kubectl wait --for=condition=Ready pod -l "${selector}" -n "${namespace}" --timeout="${timeout}s"; then
        log_error "Timeout waiting for pods to be ready"
        log_info "Pod status:"
        kubectl get pods -l "${selector}" -n "${namespace}" -o wide
        return 1
    fi
    
    log_success "All pods are ready"
}

# Scenario utilities
validate_scenario() {
    local scenario_id="$1"
    local scenario_path="${PROJECT_ROOT}/scenarios/v1.0/${scenario_id}"
    
    if [[ ! -d "${scenario_path}" ]]; then
        log_error "Scenario '${scenario_id}' not found at '${scenario_path}'"
        list_scenarios
        return 1
    fi
    
    if [[ ! -f "${scenario_path}/metadata.yaml" ]]; then
        log_warn "Scenario '${scenario_id}' missing metadata.yaml"
    fi
    
    if [[ ! -f "${scenario_path}/kustomization.yaml" ]]; then
        log_error "Scenario '${scenario_id}' missing kustomization.yaml"
        return 1
    fi
    
    log_debug "Scenario '${scenario_id}' validated"
    return 0
}

list_scenarios() {
    log_info "Available scenarios:"
    for scenario_dir in "${PROJECT_ROOT}/scenarios/v1.0"/*; do
        if [[ -d "${scenario_dir}" ]]; then
            local scenario_name
            scenario_name=$(basename "${scenario_dir}")
            echo "  - ${scenario_name}"
        fi
    done
}

# Dry run support
is_dry_run() {
    [[ "${DRY_RUN:-false}" == "true" ]]
}

dry_run_prefix() {
    if is_dry_run; then
        echo "DRY RUN: "
    fi
}

# Network utilities
check_cluster_connectivity() {
    log_info "Checking cluster connectivity..."
    
    if ! kubectl cluster-info &>/dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        log_info "Make sure kubectl is configured and cluster is running"
        return 1
    fi
    
    log_success "Cluster connectivity OK"
}

# Version utilities
get_version() {
    if [[ -f "${PROJECT_ROOT}/VERSION" ]]; then
        cat "${PROJECT_ROOT}/VERSION"
    else
        echo "dev"
    fi
}

# Export functions for use in other scripts
export -f log_info log_warn log_error log_success log_debug
export -f require_confirm check_prerequisites wait_for_namespace wait_for_pods
export -f validate_scenario list_scenarios is_dry_run dry_run_prefix
export -f check_cluster_connectivity get_version
