


### Home Lab Build 
- Linux Ubuntu 20.04 LTS Server / Deployed in Home plab
  - 32GB - SSD/MEM 
  - MicroK8s, Prometheus, 

### ubuntu 

----
Install 20.04 - packages to configure
- microk8
- prometheus 

----

`sudo microk8s start`
- start the service for the VM 

--- 
### Update Default Bash Profile 
`vim .bashrc`
- Edit aliases of the bash shell reference configuration 
- `:wq`

`kubectl="microk8s kubectl`
- Insert the test above

`. .bashrc`
- Resource the file from the 

----
User Permissions to Kubectl Binary w/in ubuntu 
`sudo usermod -a -G microk9s user`
- add a user to be able to access the micro 8s binary 

`sudo chown -R henry ~/.kube`



---
Install kubegoat 
`git clone https://github.com/madhuakula/kubernetes-goat.git`


Issue - kubectl not found
- Solution - replace first commandset 



