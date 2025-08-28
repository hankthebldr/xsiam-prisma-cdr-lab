#!/usr/bin/env bash
# KinD cluster teardown for CDR Lab
# Safely removes the KinD cluster and associated resources

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/../scripts/common.sh"

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-cdr-lab}"

usage() {
    cat << EOF
Usage: $0 [options]

Options:
  -h, --help        Show this help message
  -n, --name NAME   Cluster name (default: cdr-lab)
  -f, --force       Skip confirmation prompts
  --keep-images     Don't remove preloaded images
  -v, --verbose     Enable verbose logging

Environment Variables:
  CLUSTER_NAME      Override cluster name

Examples:
  $0                    # Delete cluster with confirmation
  $0 -n my-lab         # Delete cluster with custom name
  $0 --force           # Delete without confirmation
EOF
}

parse_args() {
    local FORCE=false
    local KEEP_IMAGES=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -n|--name)
                CLUSTER_NAME="$2"
                shift 2
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            --keep-images)
                KEEP_IMAGES=true
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
                log_error "Unexpected argument: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    export CLUSTER_NAME FORCE KEEP_IMAGES
}

check_kind_prerequisites() {
    if ! command -v kind &> /dev/null; then
        log_error "kind command not found"
        log_info "Install from: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
        return 1
    fi
    
    if ! command -v docker &> /dev/null; then
        log_error "docker command not found"
        return 1
    fi
}

check_cluster_exists() {
    if ! kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        log_warn "Cluster '${CLUSTER_NAME}' does not exist"
        log_info "Available clusters:"
        kind get clusters 2>/dev/null | sed 's/^/  /'
        return 1
    fi
    
    return 0
}

confirm_deletion() {
    if [[ "${FORCE}" == "true" ]] || is_dry_run; then
        return 0
    fi
    
    log_warn "This will permanently delete the KinD cluster '${CLUSTER_NAME}'"
    log_warn "All data in the cluster will be lost!"
    log_warn "Continue? (y/N)"
    
    read -r response
    case "${response}" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            log_info "Cluster deletion cancelled"
            return 1
            ;;
    esac
}

backup_cluster_state() {
    log_info "Creating backup of cluster state before deletion..."
    
    if is_dry_run; then
        log_info "$(dry_run_prefix)Would create backup of cluster state"
        return 0
    fi
    
    local backup_dir="backups"
    local timestamp
    timestamp=$(date +"%Y%m%d-%H%M%S")
    local backup_file="${backup_dir}/cluster-${CLUSTER_NAME}-${timestamp}.yaml"
    
    mkdir -p "${backup_dir}"
    
    # Try to backup cluster state if kubectl is available and cluster is accessible
    if command -v kubectl &>/dev/null && kubectl cluster-info --context "kind-${CLUSTER_NAME}" &>/dev/null; then
        log_info "Backing up cluster resources..."
        
        # Backup different resource types
        {
            echo "# Backup of cluster '${CLUSTER_NAME}' created on $(date)"
            echo "# Use 'kubectl apply -f' to restore (after creating cluster)"
            echo "---"
            
            # Get all namespaced resources in cdr-lab namespace
            kubectl get all,secrets,configmaps,networkpolicies,ingresses,pvc -n cdr-lab --context "kind-${CLUSTER_NAME}" -o yaml 2>/dev/null || true
            
            # Get cluster-wide resources created by the lab
            kubectl get clusterroles,clusterrolebindings,validatingadmissionwebhooks,mutatingadmissionwebhooks --context "kind-${CLUSTER_NAME}" -l "app.kubernetes.io/part-of=cdr-lab" -o yaml 2>/dev/null || true
            
        } > "${backup_file}"
        
        if [[ -s "${backup_file}" ]]; then
            log_success "Backup saved to ${backup_file}"
        else
            log_warn "Backup file is empty, removing..."
            rm -f "${backup_file}"
        fi
    else
        log_debug "Cluster not accessible, skipping backup"
    fi
}

delete_cluster() {
    log_info "Deleting KinD cluster '${CLUSTER_NAME}'..."
    
    if is_dry_run; then
        log_info "$(dry_run_prefix)Would delete KinD cluster '${CLUSTER_NAME}'"
        return 0
    fi
    
    # Delete the cluster
    if ! kind delete cluster --name "${CLUSTER_NAME}"; then
        log_error "Failed to delete cluster '${CLUSTER_NAME}'"
        return 1
    fi
    
    log_success "Cluster '${CLUSTER_NAME}' deleted successfully"
}

cleanup_docker_images() {
    if [[ "${KEEP_IMAGES}" == "true" ]]; then
        log_info "Keeping Docker images as requested"
        return 0
    fi
    
    log_info "Cleaning up lab-related Docker images..."
    
    if is_dry_run; then
        log_info "$(dry_run_prefix)Would clean up Docker images"
        return 0
    fi
    
    # List of images typically used by the lab
    local lab_images=(
        "kindest/node"
        "bkimminich/juice-shop"
        "metal3d/xmrig"
    )
    
    # Clean up dangling images first
    docker image prune -f >/dev/null 2>&1 || true
    
    # Optionally remove lab images (ask user)
    log_info "Remove lab-related Docker images? (y/N)"
    read -r response
    case "${response}" in
        [yY][eE][sS]|[yY])
            for image_pattern in "${lab_images[@]}"; do
                local images
                images=$(docker images --filter "reference=${image_pattern}*" -q 2>/dev/null || true)
                if [[ -n "${images}" ]]; then
                    log_info "Removing images matching '${image_pattern}'..."
                    # shellcheck disable=SC2086
                    docker rmi ${images} >/dev/null 2>&1 || log_warn "Failed to remove some ${image_pattern} images"
                fi
            done
            ;;
        *)
            log_info "Keeping Docker images"
            ;;
    esac
}

cleanup_kubectl_context() {
    log_info "Cleaning up kubectl context..."
    
    if is_dry_run; then
        log_info "$(dry_run_prefix)Would clean up kubectl context"
        return 0
    fi
    
    local context_name="kind-${CLUSTER_NAME}"
    
    # Remove the context if it exists
    if kubectl config get-contexts "${context_name}" &>/dev/null; then
        kubectl config delete-context "${context_name}" >/dev/null 2>&1 || {
            log_warn "Failed to delete kubectl context '${context_name}'"
        }
        log_debug "Removed kubectl context '${context_name}'"
    fi
    
    # Remove the cluster from kubeconfig if it exists  
    if kubectl config get-clusters "${context_name}" &>/dev/null; then
        kubectl config delete-cluster "${context_name}" >/dev/null 2>&1 || {
            log_warn "Failed to delete kubectl cluster '${context_name}'"
        }
        log_debug "Removed kubectl cluster '${context_name}'"
    fi
    
    # Remove the user from kubeconfig if it exists
    if kubectl config get-users "${context_name}" &>/dev/null; then
        kubectl config delete-user "${context_name}" >/dev/null 2>&1 || {
            log_warn "Failed to delete kubectl user '${context_name}'"
        }
        log_debug "Removed kubectl user '${context_name}'"
    fi
}

show_cleanup_summary() {
    log_success "KinD cluster cleanup complete!"
    log_info ""
    log_info "Summary:"
    log_info "  - Cluster '${CLUSTER_NAME}' deleted"
    log_info "  - kubectl context cleaned up"
    
    if [[ "${KEEP_IMAGES}" != "true" ]]; then
        log_info "  - Docker images cleaned up"
    fi
    
    # Show remaining clusters if any
    local remaining_clusters
    remaining_clusters=$(kind get clusters 2>/dev/null | wc -l)
    if [[ "${remaining_clusters}" -gt 0 ]]; then
        log_info "  - Remaining KinD clusters: ${remaining_clusters}"
        log_info "    $(kind get clusters 2>/dev/null | tr '\n' ' ')"
    else
        log_info "  - No remaining KinD clusters"
    fi
    
    log_info ""
    log_info "To create a new cluster:"
    log_info "  make kind-up"
}

main() {
    parse_args "$@"
    
    log_info "Tearing down KinD cluster for CDR Lab..."
    
    # Pre-flight checks
    check_kind_prerequisites
    
    if ! check_cluster_exists; then
        exit 0
    fi
    
    # Confirm deletion
    if ! confirm_deletion; then
        exit 0
    fi
    
    # Backup before deletion
    backup_cluster_state
    
    # Delete cluster and cleanup
    delete_cluster
    cleanup_kubectl_context
    cleanup_docker_images
    
    # Show summary
    show_cleanup_summary
    
    log_success "CDR Lab teardown complete!"
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
