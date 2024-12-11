#!/bin/bash

# WARNING: For educational purposes only, in a controlled environment.
# Running SUID attack simulations in a Kubernetes cluster is typically not recommended.

SHARED_DIRECTORY="/mnt/shared"
HOST_SHELL="/bin/sh"

simulate_suid_attack() {
  echo "[+] Simulating SUID Attack Technique inside Kubernetes..."

  if [ ! -w "$SHARED_DIRECTORY" ]; then
    echo "[-] Shared directory $SHARED_DIRECTORY not writable. Check volume mount."
    exit 1
  fi

  # Create the SUID executable
  echo "[+] Creating an executable SUID file in $SHARED_DIRECTORY..."
  cat << 'EOF' > $SHARED_DIRECTORY/suid_executable
#!/bin/bash
echo "Root privileges granted!"
/bin/bash
EOF

  chmod +x $SHARED_DIRECTORY/suid_executable
  # Attempt to set SUID
  chmod u+s $SHARED_DIRECTORY/suid_executable || \
    echo "[-] Unable to set SUID bit. Ensure privileged container and capabilities are enabled."

  echo "[+] Attempting to execute SUID file..."
  $HOST_SHELL -c "$SHARED_DIRECTORY/suid_executable"
}

detect_suid_attack() {
  echo "[+] Detecting SUID Attack Actions..."

  # Using inotifywait to monitor file creation
  # This will run indefinitely. Typically you'd run this in a separate container or keep it running in background.
  inotifywait -m -e create $SHARED_DIRECTORY | while read path action file; do
    echo "[ALERT] File created: $file in $path"
  done &

  # Attempting to set audit rules. May fail depending on container runtime and kernel restrictions in Kubernetes.
  echo "[+] Setting audit rules..."
  auditctl -w $SHARED_DIRECTORY -p wa -k suid_change || \
    echo "[-] auditctl failed. Check if auditd is running and container is privileged."

  auditctl -a always,exit -F path=$SHARED_DIRECTORY/suid_executable -F perm=x -F auid!=0 -k suid_execution || \
    echo "[-] Failed to add suid_execution audit rule."
}

cleanup() {
  echo "[+] Cleaning up..."
  if [ -f "$SHARED_DIRECTORY/suid_executable" ]; then
    rm -f $SHARED_DIRECTORY/suid_executable
    echo "[+] Removed $SHARED_DIRECTORY/suid_executable"
  fi

  auditctl -D 2>/dev/null || echo "[-] Failed to clear audit rules."
}

case $1 in
  attack)
    simulate_suid_attack
    ;;
  detect)
    detect_suid_attack
    ;;
  cleanup)
    cleanup
    ;;
  *)
    echo "Usage: $0 {attack|detect|cleanup}"
    exit 1
    ;;
esac