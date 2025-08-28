#!/usr/bin/env bash
# CDR Lab Cleanup Script
# Usage: cleanup.sh <scenario_id|all>

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

usage() {
    cat << EOF
Usage: $0 <scenario_id|all> [options]

Arguments:
  scenario_id    The scenario to clean up (e.g., suid, cryptominer)
  all           Clean up all scenarios

Options:
  -h, --help    Show this help message
  -d, --dry-run Show what would be deleted without deleting
  -f, --force   Skip confirmation prompts
  -v, --verbose Enable verbose logging
  --keep-namespace  Don't delete the namespace

Environment Variables:
  NAMESPACE     Target namespace (default: cdr-lab)
  DRY_RUN       Enable dry-run mode (true/false)

Examples:
  $0 cryptominer                # Clean up cryptominer scenario
  $0 all                        # Clean up all scenarios
  $0 suid --dry-run            # Show what would be deleted
  $0 all --force               # Force cleanup without confirmation

Available scenarios:
EOF
    list_scenarios
}

parse_args() {
    local FORCE=false
    local KEEP_NAMESPACE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -d|--dry-run)
                export DRY_RUN="true"
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            --keep-namespace)
                KEEP_NAMESPACE=true
                shift
                ;;
            -v|--verbose)
                export LOG_LEVEL="debug"
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                if [[ -z "${TARGET:-}" ]]; then
                    TARGET="$1"
                else
                    log_error "Too many arguments: $1"
                    usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "${TARGET:-}" ]]; then
        log_error "Missing required argument: scenario_id or 'all'"
        usage
        exit 1
    fi

    export FORCE KEEP_NAMESPACE
}

confirm_cleanup() {
    local target="$1"
    
    if [[ "${FORCE}" == "true" ]] || is_dry_run; then
        return 0
    fi
    
    if [[ "${target}" == "all" ]]; then
        log_warn "This will delete ALL scenarios and potentially the entire ${NAMESPACE} namespace"
        log_warn "Are you sure you want to continue? (y/N)"
    else
        log_warn "This will delete scenario '${target}' and all its resources"
        log_warn "Are you sure you want to continue? (y/N)"
    fi
    
    read -r response
    case "${response}" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            log_info "Cleanup cancelled"
            return 1
            ;;
    esac
}

get_scenario_resources() {
    local scenario_id="$1"
    local selector="cdr-lab/scenario-id=${scenario_id}"
    
    log_debug "Finding resources with selector: ${selector}"
    
    # Get all resource types that might exist
    local resource_types=(
        "pods" "deployments" "replicasets" "services" "configmaps" "secrets"
        "jobs" "cronjobs" "daemonsets" "statefulsets" "persistentvolumeclaims"
        "networkpolicies" "ingresses" "horizontalpodautoscalers"
    )
    
    local found_resources=()
    
    for resource_type in "${resource_types[@]}"; do
        if kubectl get "${resource_type}" -n "${NAMESPACE}" -l "${selector}" --no-headers 2>/dev/null | grep -q .; then
            found_resources+=("${resource_type}")
            log_debug "Found ${resource_type} with selector ${selector}"
        fi
    done
    
    printf '%s\n' "${found_resources[@]}"
}

show_resources() {
    local scenario_id="$1"
    local selector="cdr-lab/scenario-id=${scenario_id}"
    
    log_info "Resources that will be deleted for scenario '${scenario_id}':"
    
    if ! kubectl get all -n "${NAMESPACE}" -l "${selector}" --no-headers 2>/dev/null | grep -q .; then
        log_warn "No resources found with selector: ${selector}"
        return 1
    fi
    
    kubectl get all -n "${NAMESPACE}" -l "${selector}" -o wide
    
    # Also show other resource types
    local other_resources=(
        "configmaps" "secrets" "networkpolicies" "ingresses" 
        "persistentvolumeclaims" "horizontalpodautoscalers"
    )
    
    for resource_type in "${other_resources[@]}"; do
        if kubectl get "${resource_type}" -n "${NAMESPACE}" -l "${selector}" --no-headers 2>/dev/null | grep -q .; then
            echo ""
            log_info "${resource_type}:"
            kubectl get "${resource_type}" -n "${NAMESPACE}" -l "${selector}" -o wide
        fi
    done
    
    return 0
}

cleanup_scenario() {
    local scenario_id="$1"
    local selector="cdr-lab/scenario-id=${scenario_id}"
    
    log_info "Cleaning up scenario: ${scenario_id}"
    
    # Show what will be deleted
    if ! show_resources "${scenario_id}"; then
        log_info "No resources found for scenario '${scenario_id}'"
        return 0
    fi
    
    if is_dry_run; then
        log_info "$(dry_run_prefix)Would delete resources with selector: ${selector}"
        return 0
    fi
    
    # Delete resources by label selector
    log_info "Deleting resources with selector: ${selector}"
    
    # Delete in specific order to avoid dependency issues
    local resource_order=(
        "horizontalpodautoscalers"
        "ingresses" 
        "services"
        "deployments"
        "statefulsets"
        "daemonsets"
        "replicasets"
        "jobs"
        "cronjobs"
        "pods"
        "configmaps"
        "secrets"
        "persistentvolumeclaims"
        "networkpolicies"
    )
    
    for resource_type in "${resource_order[@]}"; do
        if kubectl get "${resource_type}" -n "${NAMESPACE}" -l "${selector}" --no-headers 2>/dev/null | grep -q .; then
            log_info "Deleting ${resource_type}..."
            kubectl delete "${resource_type}" -n "${NAMESPACE}" -l "${selector}" --wait=true --timeout=60s || {
                log_warn "Failed to delete ${resource_type}, continuing..."
            }
        fi
    done
    
    # Wait a bit for resources to be cleaned up
    log_info "Waiting for resources to be fully cleaned up..."
    sleep 5
    
    # Verify cleanup
    if kubectl get all -n "${NAMESPACE}" -l "${selector}" --no-headers 2>/dev/null | grep -q .; then
        log_warn "Some resources may still exist:"
        kubectl get all -n "${NAMESPACE}" -l "${selector}"
        log_warn "You may need to manually delete remaining resources"
    else
        log_success "All resources for scenario '${scenario_id}' have been cleaned up"
    fi
}

cleanup_all_scenarios() {
    log_info "Cleaning up ALL scenarios in namespace ${NAMESPACE}"
    
    # Get all scenarios that have resources
    local scenarios=()
    mapfile -t scenarios < <(kubectl get all -n "${NAMESPACE}" -l "cdr-lab/scenario-id" -o jsonpath='{.items[*].metadata.labels.cdr-lab/scenario-id}' 2>/dev/null | tr ' ' '\n' | sort -u | grep -v '^$')
    
    if [[ ${#scenarios[@]} -eq 0 ]]; then
        log_info "No scenarios found to clean up"
        return 0
    fi
    
    log_info "Found scenarios to clean up: ${scenarios[*]}"
    
    for scenario in "${scenarios[@]}"; do
        cleanup_scenario "${scenario}"
    done
    
    # Clean up any remaining resources in the namespace
    log_info "Cleaning up any remaining lab resources..."
    
    if is_dry_run; then
        log_info "$(dry_run_prefix)Would delete remaining resources with cdr-lab labels"
    else
        kubectl delete all -n "${NAMESPACE}" -l "cdr-lab/enabled" --wait=true --timeout=120s || {
            log_warn "Failed to delete some resources, continuing..."
        }
    fi
}

cleanup_namespace() {
    if [[ "${KEEP_NAMESPACE}" == "true" ]]; then
        log_info "Keeping namespace ${NAMESPACE} as requested"
        return 0
    fi
    
    # Check if namespace has any non-lab resources
    if kubectl get all -n "${NAMESPACE}" --no-headers 2>/dev/null | grep -v -E "(cdr-lab|gatekeeper)" | grep -q .; then
        log_warn "Namespace ${NAMESPACE} contains non-lab resources. Keeping namespace."
        log_info "Use --keep-namespace flag to suppress this warning"
        return 0
    fi
    
    log_info "Deleting namespace ${NAMESPACE}..."
    
    if is_dry_run; then
        log_info "$(dry_run_prefix)Would delete namespace ${NAMESPACE}"
        return 0
    fi
    
    kubectl delete namespace "${NAMESPACE}" --wait=true --timeout=120s || {
        log_error "Failed to delete namespace ${NAMESPACE}"
        return 1
    }
    
    log_success "Namespace ${NAMESPACE} deleted successfully"
}

show_cleanup_summary() {
    local target="$1"
    
    if is_dry_run; then
        log_info "Dry run complete - no changes were made"
        return 0
    fi
    
    log_success "Cleanup complete!"
    log_info ""
    log_info "Summary:"
    
    if [[ "${target}" == "all" ]]; then
        log_info "  - All scenarios cleaned up"
    else
        log_info "  - Scenario '${target}' cleaned up"
    fi
    
    if kubectl get namespace "${NAMESPACE}" &>/dev/null; then
        log_info "  - Namespace '${NAMESPACE}' preserved"
        log_info "  - Remaining resources:"
        kubectl get all -n "${NAMESPACE}" 2>/dev/null || log_info "    (none)"
    else
        log_info "  - Namespace '${NAMESPACE}' deleted"
    fi
    
    log_info ""
    log_info "To run scenarios again:"
    log_info "  make run scenario=<scenario_id>"
}

main() {
    parse_args "$@"
    
    log_info "Starting CDR Lab cleanup..."
    
    # Pre-flight checks
    check_prerequisites
    check_cluster_connectivity
    
    # Check if namespace exists
    if ! kubectl get namespace "${NAMESPACE}" &>/dev/null; then
        log_warn "Namespace ${NAMESPACE} does not exist"
        return 0
    fi
    
    # Confirm cleanup
    if ! confirm_cleanup "${TARGET}"; then
        exit 0
    fi
    
    # Perform cleanup
    if [[ "${TARGET}" == "all" ]]; then
        cleanup_all_scenarios
        cleanup_namespace
    else
        # Validate scenario exists
        if [[ ! -d "${PROJECT_ROOT}/scenarios/v1.0/${TARGET}" ]]; then
            log_warn "Scenario '${TARGET}' not found in scenarios directory"
            log_info "Proceeding with cleanup in case resources still exist..."
        fi
        
        cleanup_scenario "${TARGET}"
    fi
    
    show_cleanup_summary "${TARGET}"
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
