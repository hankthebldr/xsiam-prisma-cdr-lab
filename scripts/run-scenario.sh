#!/usr/bin/env bash
# CDR Lab Scenario Runner
# Usage: run-scenario.sh <scenario_id> [mode]

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/common.sh"

# Configuration
DEFAULT_MODE="safe"
REQUIRED_CONFIRMATION="I_ACKNOWLEDGE_THE_RISK"

usage() {
    cat << EOF
Usage: $0 <scenario_id> [mode]

Arguments:
  scenario_id    The scenario to run (e.g., suid, cryptominer, container-escape)
  mode          Run mode: safe (default) or unsafe

Options:
  -h, --help    Show this help message
  -d, --dry-run Run in dry-run mode (show what would be done)
  -v, --verbose Enable verbose logging

Environment Variables:
  LAB_MODE      Override the mode (safe/unsafe)
  NAMESPACE     Target namespace (default: cdr-lab)
  DRY_RUN       Enable dry-run mode (true/false)

Examples:
  $0 cryptominer                    # Run cryptominer in safe mode
  $0 suid unsafe                    # Run SUID scenario in unsafe mode
  LAB_MODE=unsafe $0 container-escape  # Run with environment variable

Available scenarios:
EOF
    list_scenarios
}

parse_args() {
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
                if [[ -z "${SCENARIO_ID:-}" ]]; then
                    SCENARIO_ID="$1"
                elif [[ -z "${MODE:-}" ]]; then
                    MODE="$1"
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
    if [[ -z "${SCENARIO_ID:-}" ]]; then
        log_error "Missing required argument: scenario_id"
        usage
        exit 1
    fi

    # Set defaults
    MODE="${MODE:-${LAB_MODE:-${DEFAULT_MODE}}}"
    export LAB_MODE="${MODE}"
    export SCENARIO_ID
}

load_scenario_metadata() {
    local metadata_file="${PROJECT_ROOT}/scenarios/v1.0/${SCENARIO_ID}/metadata.yaml"
    
    if [[ -f "${metadata_file}" ]]; then
        log_debug "Loading metadata from ${metadata_file}"
        
        # Extract metadata using basic parsing (could use yq if available)
        SCENARIO_NAME=$(grep "^name:" "${metadata_file}" | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "${SCENARIO_ID}")
        SCENARIO_RISK=$(grep "^risk:" "${metadata_file}" | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "unknown")
        SCENARIO_MITRE=$(grep "^mitre_techniques:" "${metadata_file}" | cut -d':' -f2- | sed 's/^[[:space:]]*//' || echo "")
        
        log_debug "Scenario: ${SCENARIO_NAME}, Risk: ${SCENARIO_RISK}, MITRE: ${SCENARIO_MITRE}"
    else
        log_warn "No metadata found for scenario ${SCENARIO_ID}"
        SCENARIO_NAME="${SCENARIO_ID}"
        SCENARIO_RISK="unknown"
        SCENARIO_MITRE=""
    fi
}

show_scenario_info() {
    log_info "===================================================="
    log_info "CDR Lab Scenario Runner"
    log_info "===================================================="
    log_info "Scenario: ${SCENARIO_NAME}"
    log_info "ID: ${SCENARIO_ID}"
    log_info "Mode: ${LAB_MODE}"
    log_info "Risk Level: ${SCENARIO_RISK}"
    log_info "Namespace: ${NAMESPACE}"
    
    if [[ -n "${SCENARIO_MITRE}" ]]; then
        log_info "MITRE ATT&CK: ${SCENARIO_MITRE}"
    fi
    
    if is_dry_run; then
        log_warn "DRY RUN MODE - No changes will be made"
    fi
    
    log_info "===================================================="
}

check_safety_gates() {
    local scenario_path="${PROJECT_ROOT}/scenarios/v1.0/${SCENARIO_ID}"
    
    # Check if scenario requires unsafe mode
    if [[ "${LAB_MODE}" == "unsafe" ]]; then
        log_warn "UNSAFE MODE REQUESTED"
        log_warn "This mode may perform actual attacks with real security implications"
        log_warn "Only use this in isolated lab environments"
        
        if ! is_dry_run; then
            if ! require_confirm "run scenario ${SCENARIO_ID} in unsafe mode"; then
                log_error "Safety confirmation failed"
                exit 1
            fi
        fi
    else
        log_info "Running in SAFE mode (simulated attacks only)"
    fi
    
    # Check for high-risk scenarios
    if [[ "${SCENARIO_RISK}" == "high" ]] && [[ "${LAB_MODE}" == "unsafe" ]]; then
        log_warn "HIGH RISK SCENARIO in unsafe mode"
        log_warn "This scenario may cause system damage or security breaches"
        
        if ! is_dry_run; then
            log_warn "Please confirm you understand the risks by typing: EXTREME_RISK_ACCEPTED"
            read -r user_input
            
            if [[ "${user_input}" != "EXTREME_RISK_ACCEPTED" ]]; then
                log_error "High risk scenario not confirmed. Exiting."
                exit 1
            fi
        fi
    fi
}

setup_namespace() {
    log_info "Setting up namespace ${NAMESPACE}..."
    
    if is_dry_run; then
        log_info "$(dry_run_prefix)Would create namespace ${NAMESPACE}"
        return 0
    fi
    
    # Create namespace with security labels
    kubectl apply -f - << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
  labels:
    name: ${NAMESPACE}
    cdr-lab/enabled: "true"
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
  annotations:
    cdr-lab/version: "$(get_version)"
    cdr-lab/created-by: "run-scenario.sh"
    cdr-lab/lab-mode: "${LAB_MODE}"
EOF

    wait_for_namespace "${NAMESPACE}"
}

apply_scenario() {
    local scenario_path="${PROJECT_ROOT}/scenarios/v1.0/${SCENARIO_ID}"
    local overlay_path="${PROJECT_ROOT}/overlays/${LAB_MODE}"
    
    log_info "Applying scenario ${SCENARIO_ID} with ${LAB_MODE} overlay..."
    
    if is_dry_run; then
        log_info "$(dry_run_prefix)Would apply scenario from ${scenario_path}"
        log_info "$(dry_run_prefix)Would use overlay from ${overlay_path}"
        
        # Show what would be applied
        if command -v kustomize &>/dev/null; then
            log_info "Generated manifests:"
            kustomize build "${scenario_path}" | head -20
            echo "..."
        fi
        return 0
    fi
    
    # Apply the scenario with overlay
    if [[ -d "${overlay_path}" ]]; then
        log_info "Applying with ${LAB_MODE} overlay..."
        kubectl apply -k "${overlay_path}/${SCENARIO_ID}" -n "${NAMESPACE}"
    else
        log_info "No overlay found, applying base scenario..."
        kubectl apply -k "${scenario_path}" -n "${NAMESPACE}"
    fi
    
    log_success "Scenario ${SCENARIO_ID} applied successfully"
}

wait_for_readiness() {
    if is_dry_run; then
        log_info "$(dry_run_prefix)Would wait for scenario resources to be ready"
        return 0
    fi
    
    log_info "Waiting for scenario resources to be ready..."
    
    # Wait for pods with scenario label
    local selector="cdr-lab/scenario-id=${SCENARIO_ID}"
    
    # Check if any pods exist with this selector
    if kubectl get pods -l "${selector}" -n "${NAMESPACE}" --no-headers 2>/dev/null | grep -q .; then
        wait_for_pods "${selector}" "${NAMESPACE}" 300
        
        # Show pod status
        log_info "Pod status:"
        kubectl get pods -l "${selector}" -n "${NAMESPACE}" -o wide
    else
        log_info "No pods found with selector ${selector}"
    fi
    
    # Show all resources created
    log_info "All scenario resources:"
    kubectl get all -l "${selector}" -n "${NAMESPACE}"
}

stream_logs() {
    if is_dry_run; then
        log_info "$(dry_run_prefix)Would stream logs from scenario pods"
        return 0
    fi
    
    local selector="cdr-lab/scenario-id=${SCENARIO_ID}"
    
    # Check if there are any pods to stream from
    if ! kubectl get pods -l "${selector}" -n "${NAMESPACE}" --no-headers 2>/dev/null | grep -q .; then
        log_info "No pods found to stream logs from"
        return 0
    fi
    
    log_info "Streaming logs from scenario pods (Ctrl+C to stop)..."
    log_info "You can also run: kubectl logs -f -l ${selector} -n ${NAMESPACE}"
    
    # Stream logs for 30 seconds, then exit
    timeout 30 kubectl logs -f -l "${selector}" -n "${NAMESPACE}" --all-containers=true || true
    
    log_info "Log streaming complete. Use 'make logs scenario=${SCENARIO_ID}' to view more logs."
}

show_next_steps() {
    log_success "Scenario ${SCENARIO_ID} is now running!"
    log_info ""
    log_info "Next steps:"
    log_info "  View logs:    make logs scenario=${SCENARIO_ID}"
    log_info "  Check status: kubectl get pods -n ${NAMESPACE} -l cdr-lab/scenario-id=${SCENARIO_ID}"
    log_info "  Clean up:     make cleanup scenario=${SCENARIO_ID}"
    log_info ""
    
    # Show scenario-specific instructions if available
    local readme_file="${PROJECT_ROOT}/scenarios/v1.0/${SCENARIO_ID}/README.md"
    if [[ -f "${readme_file}" ]]; then
        log_info "See ${readme_file} for scenario-specific instructions."
    fi
}

main() {
    parse_args "$@"
    
    log_info "Starting CDR Lab scenario runner..."
    
    # Pre-flight checks
    check_prerequisites
    check_cluster_connectivity
    validate_scenario "${SCENARIO_ID}"
    
    # Load scenario information
    load_scenario_metadata
    show_scenario_info
    
    # Safety checks
    check_safety_gates
    
    # Setup and deploy
    setup_namespace
    apply_scenario
    wait_for_readiness
    
    # Show results
    stream_logs
    show_next_steps
    
    log_success "Scenario ${SCENARIO_ID} deployment complete!"
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
