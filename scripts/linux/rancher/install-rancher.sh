#!/bin/bash

<<'MULTILINE-COMMENT'
    Requirments: none
    Description: Script for install and configure rancher for labs.
    Author: Marcos Silvestrini
    Date: 11/07/2023
MULTILINE-COMMENT

# Set language/locale and encoding
export LANG=C

# Set workdir
WORKDIR="/home/vagrant"
cd $WORKDIR || exit

# Variables
DISTRO=$(cat /etc/*release | grep -ws NAME=)

# Check if distribution is RPM-->Oracle Linux Server
if [[ "$DISTRO" == *"Oracle"* ]]; then
    echo "Distribution is Oracle Linux Server...Congratulations!!!"
else
    echo "This script is available only Oracle Linux Server distributions!!!";exit 1;
fi

# Install helm

## on the server rancher1
## add helm
curl -#L https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

## add needed helm charts
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
helm repo add jetstack https://charts.jetstack.io

## add the cert-manager CRD
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.1/cert-manager.crds.yaml

## helm install jetstack
helm upgrade -i cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace

## helm install rancher
helm upgrade -i rancher rancher-latest/rancher --create-namespace --namespace cattle-system --set hostname=control-plane01.skynet.com.br --set bootstrapPassword=bootStrapAllTheThings --set replicas=1

## Output

# NOTE: Rancher may take several minutes to fully initialize. Please standby while Certificates are being issued, Containers are started and the Ingress rule comes up.
# Check out our docs at https://rancher.com/docs/
# If you provided your own bootstrap password during installation, browse to https://control-plane01.skynet.com.br to get started.
# If this is the first time you installed Rancher, get started by running this command and clicking the URL it generates:
# ```
# echo https://control-plane01.skynet.com.br/dashboard/?setup=$(kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}')
# ```
# To get just the bootstrap password on its own, run:
# ```
# kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}{{ "\n" }}'
# ```

## uninstall rancer
# helm uninstall rancher --namespace cattle-system