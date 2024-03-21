# Helps Kubernetes

## RKE2

### Install RKE2

<https://ranchergovernment.com/blog/article-simple-rke2-longhorn-and-rancher-install>

### Install RKE2 HA with DNS Round Robin

<https://medium.com/@osmarrleao/deploy-rancher-on-rke-cluster-e7415c199ef2>
<https://docs.expertflow.com/cx/rke2-deployment-in-high-availability-with-dns-195855071.html?selectedPageVersions=18&selectedPageVersions=19>

### About RKE2 load balance

<https://www.mattgerega.com/2023/02/15/automated-rke2-cluster-management/>

### Fix RKE2 error get ip of not mapped in dns

```sh
systemctl stop rke2-server.service
systemctl stop NetworkManager
ip route add default  via 192.168.0.1 dev eth1
#systemctl disable NetworkManager
#ip link set eth0 down
rm  /var/lib/rancher/rke2/agent/pod-manifests/etcd.yaml
systemctl start rke2-server.service
set linux for disable
```

### Fix error server is not ready: Node password rejected

Erro:\
Jul 17 09:09:33 worker02 rke2[36806]: time="2023-07-17T09:09:33-03:00" level=info msg="Waiting to retrieve agent configuration; server is not ready:\
Node password rejected, duplicate hostname or contents of '/etc/rancher/node/password' may not match server node-passwd entry,\
try enabling a unique node name with the --with-node-id flag"

Solution:

```sh
kubectl -n kube-system delete secrets <agent-node-name>.node-password.rke2
```

## Kubectl

## Install kubectl autocomplete windows

```sh
kubectl completion powershell | Out-String | Invoke-Expression
```

## HAProxy

<https://www.suse.com/support/kb/doc/?id=000020175>

## Set ips for RKe2

https://github.com/rancher/rke2/issues/910

## Get node internal ip

kubectl get nodes -o wide | awk -v OFS='\t\t' '{print $1, $6, $7}'

## Delete node

```sh
# Run on Master
kubectl cordon <node-name>
kubectl drain <node-name> --force --ignore-daemonsets  --delete-emptydir-data
kubectl delete node <node-name>
```

## Namespaces

### show you what resources remain in the namespace

```sh
kubectl api-resources --verbs=list --namespaced -o name \
  | xargs -n 1 kubectl get --show-kind --ignore-not-found -n <namespace>
```

### Delete namespace in state Terminating

```sh
kubectl get namespace "stucked-namespace" -o json \
  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  | kubectl replace --raw /api/v1/namespaces/stucked-namespace/finalize -f -

```

## Access Kubernetes Dashboard

* Create ssh tunel

```sh
ssh -o StrictHostKeyChecking=no -L localhost:8001:127.0.0.1:8001 root@192.168.0.140
```

* Deploy dashboard

https://upcloud.com/resources/tutorials/deploy-kubernetes-dashboard

* Create dashboard token

```sh  
kubectl create token admin-user -n kubernetes-dashboard
```

* Access dashboard

<http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#/workloads?namespace=default>

## Deploy app

```sh
kubectl apply -f https://raw.githubusercontent.com/marcossilvestrini/learning-kubernetes/main/apps/app-silvestrini/deployment.yaml
```

## Deploy loadbalancer metallb

```sh
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml
```

## Expose service with port-forward

<https://www.middlewareinventory.com/blog/kubectl-port-forward/>

```sh
# expose argocd - ip 192.168.0.100---->local port 443--->remote port 8080[192.168.0.100:8080]
kubectl port-forward svc/argocd-server -n argocd 8080:443 --address='192.168.0.100'

# expose argocd - all ips--->local port 443--->remote port 8080[192.168.0.100:8080]
kubectl port-forward svc/argocd-server -n argocd 8080:443 --address='0.0.0.0'
```

## Logging

```sh
# get logs of all pods cilium
stern -n kube-system cilium --max-log-requests 100 -t --since 10m 

# debug tree process
strace -cf -p  <PID>
```

## Check status deployments\pods as ok

kubectl wait --for condition=containersready -n longhorn-system pod --all --timeout=300s

## etcd

<https://etcd.io/>

### etcd defrag

```sh
kubectl exec $(kubectl get pods --selector=component=etcd -A -o name | head -n 1) \
-n kube-system \
-- etcdctl defrag \
--cluster \
--cacert /var/lib/rancher/rke2/server/tls/etcd/server-ca.crt \
--key /var/lib/rancher/rke2/server/tls/etcd/server-client.key \
--cert /var/lib/rancher/rke2/server/tls/etcd/server-client.crt
```

## Deployments

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