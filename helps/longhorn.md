# Longhorn helps

## Repo oficial

<https://github.com/longhorn/longhorn/tree/master>

## Access ui

<https://community.exoscale.com/documentation/sks/longhorn-exoscale-sks/>

kubectl port-forward deployment/longhorn-ui 7000:8000 -n longhorn-system

## Examples Deploy

<https://imixs.github.io/imixs-cloud/management/longhorn/>

## Install helm chart

```zsh
helm repo add longhorn https://charts.longhorn.io
helm repo update
helm upgrade --install longhorn longhorn/longhorn \
    --namespace longhorn-system \
    --create-namespace \
    --values configs/longhorn/values.yaml
kubectl wait --for condition=containersready -n longhorn-system pod --all --timeout=300s
```

## Uninstall helm chart

```sh
helm uninstall longhorn -n longhorn-system

# Delete CRD finalizers, instances and definitions
for crd in $(kubectl get crd -o jsonpath={.items[*].metadata.name} | tr ' ' '\n' | grep longhorn.rancher.io); do
  kubectl -n ${NAMESPACE} get $crd -o yaml | sed "s/\- longhorn.rancher.io//g" | kubectl apply -f -
  kubectl -n ${NAMESPACE} delete $crd --all
  kubectl delete crd/$crd
done

# Clean CRD
kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/v1.5.1/uninstall/uninstall.yaml
kubectl get job/longhorn-uninstall -n longhorn-system -w


#Remove remaining components:
kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v1.5.1/deploy/longhorn.yaml
kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/v1.5.1/uninstall/uninstall.yaml


##################### IF FAILED #####################
# Delete namespace
kubectl delete namespace longhorn-system

# Delete all resources associated
kubectl get namespace "longhorn-system" -o json   | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/"   | kubectl replace --raw /api/v1/namespaces/longhorn-system/finalize -f -
```
