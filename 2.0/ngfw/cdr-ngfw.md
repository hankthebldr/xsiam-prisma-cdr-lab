


https://github.com/alphasoc/flightsim


## Create a container for WF 
kubectl run wf --image=busybox --restart=Never -- /bin/sh -c "while true; do sleep 30; done"

## Exec into pod, curl script and execute 
kubectl exec -it malicious-container -- /bin/sh wget -qO- https://raw.githubusercontent.com/hankthebldr/xsiam-prisma-cdr-lab/refs/heads/alpha/ngfw/wildfire-samples.sh | sh

## Create Kuberentes object with YAML 
kubectl apply -f /ngfw/ngfw-traffic 