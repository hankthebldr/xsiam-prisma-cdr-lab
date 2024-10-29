#!/bin/bash

# This script demonstrates several insecure container scenarios commonly seen in the industry.
# It is intended for educational purposes only and should only be run in a secure, isolated environment.

# Create a directory to store downloaded resources
DOWNLOAD_DIR="/tmp/insecure_container_scenarios"
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

# Scenario 1: Running a container with root privileges
run_scenario "Running a container with root privileges" \
    "docker run -d --name insecure-root-container --user root nginx:alpine"

# Scenario 2: Running a container without resource limits (CPU, memory)
run_scenario "Running a container without resource limits" \
    "docker run -d --name no-resource-limits nginx:alpine"

# Scenario 3: Running a container with privilege escalation allowed
run_scenario "Running a container with privilege escalation allowed" \
    "docker run -d --name privileged-container --privileged nginx:alpine"

# Scenario 4: Running a container without dropping capabilities
run_scenario "Running a container without dropping capabilities" \
    "docker run -d --name full-capabilities-container nginx:alpine"

# Scenario 5: Mounting sensitive host directories into the container
run_scenario "Mounting sensitive host directory (/etc) into the container" \
    "docker run -d --name sensitive-mount -v /etc:/mnt/etc nginx:alpine"

# Scenario 6: Running a container with an outdated and vulnerable image
run_scenario "Running a container with an outdated and vulnerable image" \
    "docker run -d --name outdated-container vulnerables/web-dvwa:latest"

# Scenario 7: Storing credentials in environment variables
run_scenario "Storing credentials in environment variables" \
    "docker run -d --name env-credentials -e MYSQL_USER=root -e MYSQL_PASSWORD=password123 mysql:5.7"

# Scenario 8: Running a container with an insecure network setting (host network mode)
run_scenario "Running a container in host network mode" \
    "docker run -d --name host-network-container --network host nginx:alpine"

# Scenario 9: Running a container with read-write access to root filesystem
run_scenario "Running a container with read-write access to root filesystem" \
    "docker run -d --name rw-rootfs -v /:/mnt/rw-root nginx:alpine"

# Cleanup: stop and remove all insecure containers created by this script
function cleanup() {
    echo "\nCleaning up..."
    docker rm -f insecure-root-container no-resource-limits privileged-container full-capabilities-container sensitive-mount outdated-container env-credentials host-network-container rw-rootfs
}

trap cleanup EXIT

# Summary and Warning
cat << EOF

This script has demonstrated a series of common insecure container configurations, including:
1. Running containers with root privileges.
2. Running containers without resource limits.
3. Allowing privilege escalation.
4. Not dropping capabilities.
5. Mounting sensitive host directories.
6. Using outdated, vulnerable container images.
7. Storing credentials in environment variables.
8. Running containers in host network mode.
9. Allowing read-write access to the root filesystem.

These scenarios are meant to illustrate insecure practices for educational purposes only.
Do not run these configurations in production environments.
EOF
