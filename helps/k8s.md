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

## Get node internal ip

kubectl get nodes -o wide | awk -v OFS='\t\t' '{print $1, $6, $7}'

## Delete node

```sh
Run on Master
# kubectl cordon <node-name>
# kubectl drain <node-name> --force --ignore-daemonsets  --delete-emptydir-data
# kubectl delete node <node-name>
```
