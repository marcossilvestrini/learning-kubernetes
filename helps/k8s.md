# Helps Kubernetes

## Install kubectl autocomplete windows

kubectl completion powershell | Out-String | Invoke-Expression

## Fix RKE2 error get ip of not mapped in dns

systemctl stop rke2-server.service
systemctl stop NetworkManager
ip route add default  via 192.168.0.1 dev eth1
#systemctl disable NetworkManager
#ip link set eth0 down
rm  /var/lib/rancher/rke2/agent/pod-manifests/etcd.yaml
systemctl start rke2-server.service
set linux for disable

## Fix error server is not ready: Node password rejected

Erro:\
Jul 17 09:09:33 worker02 rke2[36806]: time="2023-07-17T09:09:33-03:00" level=info msg="Waiting to retrieve agent configuration; server is not ready:\
Node password rejected, duplicate hostname or contents of '/etc/rancher/node/password' may not match server node-passwd entry,\
try enabling a unique node name with the --with-node-id flag"

Solution:\
kubectl -n kube-system delete secrets <agent-node-name>.node-password.rke2

## HAProxy

<https://www.suse.com/support/kb/doc/?id=000020175>

Set ips for RKe2
https://github.com/rancher/rke2/issues/910

## Install RKE2 HA with DNS Round Robin

<https://medium.com/@osmarrleao/deploy-rancher-on-rke-cluster-e7415c199ef2>
<https://docs.expertflow.com/cx/rke2-deployment-in-high-availability-with-dns-195855071.html?selectedPageVersions=18&selectedPageVersions=19>

## About RKE2load balance

<https://www.mattgerega.com/2023/02/15/automated-rke2-cluster-management/>

## Get node internal ip

kubectl get nodes -o wide | awk -v OFS='\t\t' '{print $1, $6, $7}'

## Delete node

```sh
Run on Master
# kubectl cordon <node-name>
# kubectl drain <node-name> --force --ignore-daemonsets  --delete-emptydir-data
# kubectl delete node <node-name>
```

## Deploy Full App

* build a docker image for app
* push image to register
* create a storage class
* create pv
* create pvc
* create service
* create pods with deployment
  * create containers with your images
  * create probes for check health containers


## Access Kubernetes Dashboard

* Create ssh tunel

```sh
ssh -L localhost:8001:127.0.0.1:8001 root@192.168.0.140
```

* Deploy dashboard

https://upcloud.com/resources/tutorials/deploy-kubernetes-dashboard
