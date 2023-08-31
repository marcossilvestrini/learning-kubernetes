#!/usr/bin/env bash

# Up test for dynamic-localpv provisioner

# Namespace
NAMESPACE_OPENEBS="openebs-localpv"
NAMESPACE_APP="openebs-localpv-test"

# Clear resources
kubectl delete  -f app/pod.yaml
kubectl delete -f app/pvc.yaml
kubectl delete namespace $NAMESPACE_APP
helm uninstall -n openebs-localpv openebs-localpv 
kubectl delete namespace $NAMESPACE_OPENEBS
kubectl delete storageclasses.storage.k8s.io openebs-device 
kubectl delete storageclasses.storage.k8s.io openebs-hostpath

# Create namespace for test
kubectl create namespace $NAMESPACE_APP

# install chart
helm repo add openebs-localpv https://openebs.github.io/dynamic-localpv-provisioner
helm repo update
helm upgrade -i \
    --install openebs-localpv openebs-localpv/localpv-provisioner \
    --namespace openebs-localpv  \
    --create-namespace \
    -f chart/values.yaml

# Create pvc
kubectl apply -f app/pvc.yaml

# Create pod for test
kubectl apply  -f app/pod.yaml

# Waiting deployment
kubectl wait --for condition=containersready -n $NAMESPACE_APP pod --all --timeout=300s

# Execute test
kubectl -n $NAMESPACE_APP exec busybox -- ls -lt /mnt/data