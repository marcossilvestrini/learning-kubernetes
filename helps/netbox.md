# Helps Netbox

## Helm Chart

https://github.com/bootc/netbox-chart

## Get the application URL by running these commands

export POD_NAME=$(kubectl get pods --namespace netbox -l "app.kubernetes.io/name=netbox,app.kubernetes.io/instance=netbox" -o jsonpath="{.items[0].metadata.name}")
echo "Visit http://127.0.0.1:8080 to use your application"
kubectl port-forward $POD_NAME 8080:8080