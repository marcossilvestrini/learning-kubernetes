# Docs OpenEBS

## Official Doc

<https://openebs.io/docs>

## Cas Engines

<https://openebs.io/docs/main/concepts/casengines>

Mayastor\
cStor\
Jiva

## Local PV Hostpath

<https://openebs.io/docs/user-guides/localpv-hostpath>

## Prerequisites

Setup the directory on the nodes where Local PV Hostpaths will be created.\
This directory will be referred to as BasePath. The default location is /var/openebs/local.

### PV Hostpath labs

kubectl apply -f https://openebs.github.io/charts/examples/local-hostpath/local-hostpath-pvc.yaml
kubectl apply -f https://openebs.github.io/charts/examples/local-hostpath/local-hostpath-pod.yaml
kubectl get pod hello-local-hostpath-pod
kubectl get pvc local-hostpath-pvc