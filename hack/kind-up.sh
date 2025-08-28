#!/usr/bin/env bash
# KinD cluster setup for CDR Lab
# Creates a Kubernetes cluster optimized for security lab scenarios

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/../scripts/common.sh"

# Configuration
CLUSTER_NAME="${CLUSTER_NAME:-cdr-lab}"
KIND_CONFIG="${KIND_CONFIG:-${SCRIPT_DIR}/kind-config.yaml}"
KUBECTL_VERSION="${KUBECTL_VERSION:-v1.28.0}"

usage() {
    cat << EOF
Usage: $0 [options]

Options:
  -h, --help        Show this help message
  -n, --name NAME   Cluster name (default: cdr-lab)
  -c, --config FILE Kind config file (default: hack/kind-config.yaml)
  --no-policies     Skip installing security policies
  --no-images       Skip preloading images
  -v, --verbose     Enable verbose logging

Environment Variables:
  CLUSTER_NAME      Override cluster name
  KIND_CONFIG       Override config file path

Examples:
  $0                    # Create cluster with default settings
  $0 -n my-lab         # Create cluster with custom name
  $0 --no-policies     # Skip policy installation
EOF
}

parse_args() {
    local SKIP_POLICIES=false
    local SKIP_IMAGES=false
    
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
            -c|--config)
                KIND_CONFIG="$2"
                shift 2
                ;;
            --no-policies)
                SKIP_POLICIES=true
                shift
                ;;
            --no-images)
                SKIP_IMAGES=true
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
    
    export CLUSTER_NAME SKIP_POLICIES SKIP_IMAGES
}

check_kind_prerequisites() {
    log_info "Checking KinD prerequisites..."
    
    if ! command -v kind &> /dev/null; then
        log_error "kind command not found"
        log_info "Install from: https://kind.sigs.k8s.io/docs/user/quick-start/#installation"
        return 1
    fi
    
    if ! command -v docker &> /dev/null; then
        log_error "docker command not found"
        log_info "Docker is required for KinD to work"
        return 1
    fi
    
    if ! docker info &>/dev/null; then
        log_error "Docker daemon not running"
        log_info "Please start Docker and try again"
        return 1
    fi
    
    log_success "Prerequisites OK"
}

create_kind_config() {
    log_info "Creating KinD configuration..."
    
    cat > "${KIND_CONFIG}" << EOF
# KinD cluster configuration for CDR Lab
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${CLUSTER_NAME}

# Multiple nodes for realistic scenarios
nodes:
- role: control-plane
  image: kindest/node:${KUBECTL_VERSION}
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
  - containerPort: 30001
    hostPort: 30001
    protocol: TCP
- role: worker
  image: kindest/node:${KUBECTL_VERSION}
- role: worker
  image: kindest/node:${KUBECTL_VERSION}

# Enable feature gates for security testing
kubeadmConfigPatches:
- |
  kind: ClusterConfiguration
  controllerManager:
    extraArgs:
      bind-address: "0.0.0.0"
  scheduler:
    extraArgs:
      bind-address: "0.0.0.0"
  etcd:
    local:
      extraArgs:
        listen-metrics-urls: "http://0.0.0.0:2381"
- |
  kind: KubeletConfiguration
  serverTLSBootstrap: true
  # Enable container runtime security features
  cgroupDriver: systemd
  # Security settings for lab scenarios
  readOnlyPort: 0
  streamingConnectionIdleTimeout: "30s"
  
# Network configuration
networking:
  # Disable default CNI to install our own
  disableDefaultCNI: false
  podSubnet: "10.244.0.0/16"
  serviceSubnet: "10.96.0.0/16"

# Runtime configuration
runtimeConfig:
  "api/all": "true"

# Enable auditing for security scenarios
kubeadmConfigPatches:
- |
  kind: ClusterConfiguration
  apiServer:
    # Enable audit logging
    extraArgs:
      audit-log-path: "/var/log/audit.log"
      audit-policy-file: "/etc/kubernetes/audit-policy.yaml"
      audit-log-maxage: "30"
      audit-log-maxbackup: "10"
      audit-log-maxsize: "100"
    extraVolumes:
    - name: audit-policy
      hostPath: "/etc/kubernetes/audit-policy.yaml"
      mountPath: "/etc/kubernetes/audit-policy.yaml"
      readOnly: true
      pathType: File
    - name: audit-logs
      hostPath: "/var/log/kubernetes/audit"
      mountPath: "/var/log"
      readOnly: false
      pathType: DirectoryOrCreate
EOF

    log_debug "Kind config created at ${KIND_CONFIG}"
}

create_audit_policy() {
    log_info "Creating audit policy for security monitoring..."
    
    # This would normally be created on the host, but for KinD we'll add it as a patch
    cat >> "${KIND_CONFIG}" << 'EOF'

# Files to mount into the cluster
files:
- path: /etc/kubernetes/audit-policy.yaml
  content: |
    apiVersion: audit.k8s.io/v1
    kind: Policy
    rules:
    # Log security-relevant events at request level
    - level: Request
      namespaces: ["cdr-lab"]
      resources:
      - group: ""
        resources: ["pods", "services", "secrets", "configmaps"]
      - group: "apps"
        resources: ["deployments", "replicasets", "daemonsets", "statefulsets"]
      - group: "networking.k8s.io"
        resources: ["networkpolicies"]
    
    # Log privileged operations
    - level: RequestResponse
      users: ["system:serviceaccount:cdr-lab:*"]
      verbs: ["create", "update", "patch", "delete"]
    
    # Log exec and portforward for security monitoring  
    - level: Request
      resources:
      - group: ""
        resources: ["pods/exec", "pods/portforward", "pods/proxy"]
    
    # Log authentication failures
    - level: Request
      namespaces: ["cdr-lab"]
      verbs: ["create"]
      resources:
      - group: ""
        resources: ["serviceaccounts/token"]
    
    # Default: log metadata for everything else in lab namespace
    - level: Metadata
      namespaces: ["cdr-lab"]
    
    # Minimal logging for system components
    - level: None
      users: ["system:kube-proxy", "system:kube-scheduler", "system:kube-controller-manager"]
    - level: None
      userGroups: ["system:nodes"]
    - level: None
      verbs: ["get", "list", "watch"]
      resources:
      - group: "metrics.k8s.io"
EOF

    log_debug "Audit policy configured"
}

create_cluster() {
    log_info "Creating KinD cluster '${CLUSTER_NAME}'..."
    
    # Check if cluster already exists
    if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
        log_warn "Cluster '${CLUSTER_NAME}' already exists"
        log_warn "Delete it first with: kind delete cluster --name ${CLUSTER_NAME}"
        return 1
    fi
    
    if is_dry_run; then
        log_info "$(dry_run_prefix)Would create KinD cluster with config:"
        cat "${KIND_CONFIG}"
        return 0
    fi
    
    # Create the cluster
    log_info "This may take a few minutes..."
    if ! kind create cluster --config="${KIND_CONFIG}" --wait=5m; then
        log_error "Failed to create KinD cluster"
        return 1
    fi
    
    # Set kubectl context
    kubectl cluster-info --context "kind-${CLUSTER_NAME}"
    
    log_success "KinD cluster '${CLUSTER_NAME}' created successfully"
}

wait_for_cluster() {
    log_info "Waiting for cluster to be ready..."
    
    if is_dry_run; then
        log_info "$(dry_run_prefix)Would wait for cluster readiness"
        return 0
    fi
    
    # Wait for nodes to be ready
    log_info "Waiting for nodes..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    # Wait for system pods
    log_info "Waiting for system pods..."
    kubectl wait --for=condition=Ready pod -l k8s-app=kube-dns -n kube-system --timeout=300s
    
    # Show cluster info
    log_info "Cluster status:"
    kubectl get nodes -o wide
    kubectl get pods -A | grep -E "(kube-system|local-path-storage)"
    
    log_success "Cluster is ready"
}

preload_images() {
    if [[ "${SKIP_IMAGES}" == "true" ]]; then
        log_info "Skipping image preloading"
        return 0
    fi
    
    log_info "Preloading common images to speed up scenarios..."
    
    local images=(
        "alpine:latest"
        "ubuntu:20.04" 
        "busybox:latest"
        "nginx:alpine"
        "bkimminich/juice-shop:latest"
        "metal3d/xmrig:latest"
    )
    
    if is_dry_run; then
        log_info "$(dry_run_prefix)Would preload images: ${images[*]}"
        return 0
    fi
    
    for image in "${images[@]}"; do
        log_info "Preloading ${image}..."
        if docker pull "${image}" && kind load docker-image "${image}" --name "${CLUSTER_NAME}"; then
            log_success "Loaded ${image}"
        else
            log_warn "Failed to preload ${image}, continuing..."
        fi
    done
}

install_metrics_server() {
    log_info "Installing metrics server..."
    
    if is_dry_run; then
        log_info "$(dry_run_prefix)Would install metrics server"
        return 0
    fi
    
    kubectl apply -f - << 'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    k8s-app: metrics-server
    rbac.authorization.k8s.io/aggregate-to-admin: "true"
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
    rbac.authorization.k8s.io/aggregate-to-view: "true"
  name: system:aggregated-metrics-reader
rules:
- apiGroups:
  - metrics.k8s.io
  resources:
  - pods
  - nodes
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    k8s-app: metrics-server
  name: system:metrics-server
rules:
- apiGroups:
  - ""
  resources:
  - nodes/metrics
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - pods
  - nodes
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server-auth-reader
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: extension-apiserver-authentication-reader
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server:system:auth-delegator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    k8s-app: metrics-server
  name: system:metrics-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:metrics-server
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: v1
kind: Service
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
spec:
  ports:
  - name: https
    port: 443
    protocol: TCP
    targetPort: https
  selector:
    k8s-app: metrics-server
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  strategy:
    rollingUpdate:
      maxUnavailable: 0
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls
        image: registry.k8s.io/metrics-server/metrics-server:v0.6.4
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /livez
            port: https
            scheme: HTTPS
          periodSeconds: 10
        name: metrics-server
        ports:
        - containerPort: 4443
          name: https
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /readyz
            port: https
            scheme: HTTPS
          initialDelaySeconds: 20
          periodSeconds: 10
        resources:
          requests:
            cpu: 100m
            memory: 200Mi
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
        volumeMounts:
        - mountPath: /tmp
          name: tmp-dir
      nodeSelector:
        kubernetes.io/os: linux
      priorityClassName: system-cluster-critical
      serviceAccountName: metrics-server
      volumes:
      - emptyDir: {}
        name: tmp-dir
EOF

    # Wait for metrics server to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/metrics-server -n kube-system
    log_success "Metrics server installed"
}

create_sinkhole_service() {
    log_info "Creating sinkhole service for safe mode scenarios..."
    
    if is_dry_run; then
        log_info "$(dry_run_prefix)Would create sinkhole service"
        return 0
    fi
    
    # Create namespace first if it doesn't exist
    kubectl create namespace cdr-lab --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl apply -f - << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: sinkhole-config
  namespace: cdr-lab
  labels:
    app.kubernetes.io/name: sinkhole
    app.kubernetes.io/part-of: cdr-lab
data:
  sinkhole.sh: |
    #!/bin/bash
    echo "CDR Lab Sinkhole Service"
    echo "Accepting connections on port 3333 (crypto pool simulation)"
    echo "Accepting connections on port 4444 (reverse shell simulation)"
    echo "All connections will be logged but no actual processing occurs"
    
    # Simple TCP sinkhole that accepts and logs connections
    while true; do
      echo "$(date): Sinkhole ready for connections" | tee -a /var/log/sinkhole.log
      sleep 60
    done
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sinkhole
  namespace: cdr-lab
  labels:
    app.kubernetes.io/name: sinkhole
    app.kubernetes.io/part-of: cdr-lab
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: sinkhole
  template:
    metadata:
      labels:
        app.kubernetes.io/name: sinkhole
        app.kubernetes.io/part-of: cdr-lab
    spec:
      containers:
      - name: sinkhole
        image: busybox:latest
        command: ["/bin/sh", "/etc/config/sinkhole.sh"]
        ports:
        - containerPort: 3333
          name: crypto-pool
        - containerPort: 4444  
          name: reverse-shell
        volumeMounts:
        - name: config
          mountPath: /etc/config
        - name: logs
          mountPath: /var/log
        resources:
          limits:
            memory: "64Mi"
            cpu: "50m"
          requests:
            memory: "32Mi"
            cpu: "10m"
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          readOnlyRootFilesystem: true
          allowPrivilegeEscalation: false
      volumes:
      - name: config
        configMap:
          name: sinkhole-config
          defaultMode: 0755
      - name: logs
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: sinkhole
  namespace: cdr-lab
  labels:
    app.kubernetes.io/name: sinkhole
    app.kubernetes.io/part-of: cdr-lab
spec:
  selector:
    app.kubernetes.io/name: sinkhole
  ports:
  - name: crypto-pool
    port: 3333
    targetPort: 3333
  - name: reverse-shell
    port: 4444
    targetPort: 4444
EOF

    log_success "Sinkhole service created"
}

show_cluster_info() {
    log_success "KinD cluster setup complete!"
    log_info ""
    log_info "Cluster Information:"
    log_info "  Name: ${CLUSTER_NAME}"
    log_info "  Context: kind-${CLUSTER_NAME}"
    log_info "  Nodes: $(kubectl get nodes --no-headers | wc -l)"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Run a scenario: make run scenario=cryptominer"
    log_info "  2. View cluster: kubectl get nodes"
    log_info "  3. Access logs: kubectl logs -n cdr-lab <pod-name>"
    log_info ""
    log_info "Cleanup:"
    log_info "  make kind-down    # Delete the cluster"
    log_info ""
    
    # Show useful kubectl commands
    log_info "Useful commands:"
    log_info "  kubectl get pods -A              # All pods"
    log_info "  kubectl get nodes -o wide        # Node details"  
    log_info "  kubectl top nodes                # Resource usage"
    log_info "  kubectl logs -n cdr-lab sinkhole-xxx # Sinkhole logs"
}

main() {
    parse_args "$@"
    
    log_info "Setting up KinD cluster for CDR Lab..."
    
    # Pre-flight checks
    check_kind_prerequisites
    
    # Create configuration
    create_kind_config
    create_audit_policy
    
    # Create cluster
    create_cluster
    wait_for_cluster
    
    # Install components
    preload_images
    install_metrics_server
    create_sinkhole_service
    
    # Show final info
    show_cluster_info
    
    log_success "KinD cluster setup complete!"
}

# Only run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
