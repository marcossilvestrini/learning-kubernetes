# Helps Kube-Prometheus

## Official repository

<https://github.com/prometheus-operator/kube-prometheus>
<https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack>
<https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml>

## Deploy Prometheus monitoring stack to Kubernetes with a single Helm Chart

<https://k21academy.com/docker-kubernetes/prometheus-grafana-monitoring/>
https://spacelift.io/blog/prometheus-kubernetes

## Add repo

```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add stable https://charts.helm.sh/stable
```

## Update helm repo

```sh
helm repo update
```

## Create namespace

```sh
kubectl create ns kube
```

## Install kube-prometheus stack

```sh
helm install -n kube prometheus prometheus-community/kube-prometheus-stack

## check install

```sh
kubectl get all -n kube
```

## Access Prometheus Dashboard

All services are defined as ClusterIP in default configuration. To access, we are going to use port-forward.\
However we can edit the service or edit the value upon deployment to use NodePort or Ingress.

```sh
kubectl port-forward deployment/prometheus-grafana 3000
```

## Access Grafana Dashboard

http://localhost:3000
user: admin
password: prom-operator

## Show charts

helm show values prometheus-community/kube-prometheus-stack

## Uninstall

```sh
helm list
helm uninstall [RELEASE_NAME]
```

## Remove CRDs

```sh
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd probes.monitoring.coreos.com
kubectl delete crd prometheusagents.monitoring.coreos.com
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd scrapeconfigs.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
```

## Configure node-exporter

helm install node-exporter prometheus-community/prometheus-node-exporter

## Access node-exporter

kubectl port-forward --namespace silvestrini $POD_NAME 9100

## Examples Deployment

https://support.tools/post/how-to-install-kube-prometheus-stack/<>>
