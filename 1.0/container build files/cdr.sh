#!/bin/bash
# This script interacts with the local MicroK8s cluster to deploy a test environment with malware samples.
# WARNING: This script downloads and runs real malware. Use in a secure, isolated environment ONLY.
# TODO configure the escapable container within the microk8s cluster --- how to make the CGO/CMD execution to assume a role 
# Function to check if MicroK8s is running

check_microk8s() {
  echo "[+] Checking MicroK8s status..."
  if ! microk8s status --wait-ready >/dev/null 2>&1; then
    echo "[-] MicroK8s is not running or not installed. Please start MicroK8s."
    exit 1
  fi
  echo "[+] MicroK8s is running."
}
#  Function to download the required containers to the local server 

microk8s kubectl exec -it podname -- sh 

# Function to exec into the container
exec_into_container() {
  POD_NAME=$1
  echo "Executing into the container ${POD_NAME}..."
  microk8s kubectl exec -it ${POD_NAME} -- /bin/bash
}



# Main script execution
check_microk8s
exec_into_container


