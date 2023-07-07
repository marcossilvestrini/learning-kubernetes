# Helps Kubernetes

## Fix RKE2 error get ip of not mapped in dns

systemctl stop rke2-server.service
systemctl stop NetworkManager
ip route add default  via 192.168.0.1 dev eth1
#systemctl disable NetworkManager
#ip link set eth0 down
rm  /var/lib/rancher/rke2/agent/pod-manifests/etcd.yaml
systemctl start rke2-server.service
set linux for disable

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
