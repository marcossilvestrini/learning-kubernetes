#!/bin/bash

#  RKE2 Docs
# https://docs.rke2.io/install/quickstart
# https://docs.rke2.io/install/ha
# https://docs.rke2.io/reference/server_config
# https://computingforgeeks.com/deploy-kubernetes-on-rocky-using-rke2/?expand_article=1

<<'MULTILINE-COMMENT'
    Requirments: none
    Description: Script for deployments apps in rke2 cluster for labs.
    Author: Marcos Silvestrini
    Date: 21/07/2023
MULTILINE-COMMENT

# Function for init procedures
function init() {
    # Set language/locale and encoding
    export LANG=C

    # Set workdir
    WORKDIR="/home/vagrant"
    cd $WORKDIR || exit

    # Variables
    DISTRO=$(cat /etc/*release | grep -ws NAME=)
    NODE_MASTER="control-plane01"
    NODE_NAME=$(hostname)

    # Check if distribution is RPM-->Oracle Linux Server
    if [[ "$DISTRO" == *"Oracle"* ]]; then
        echo "CHECK IF DISTRIBUTION IS ORACLE..."
        echo "CONGRATULATIONS, YOUR DISTRO SO GOOD!"
    else
        echo "THIS SCRIPT IS AVAILABLE ONLY ORACLE LINUX SERVER DISTRIBUTIONS!!!"
        exit 1
    fi
}

function cert-manager() {
    if [[ "$NODE_MASTER" == *"$NODE_NAME"* ]]; then
        # Deploy cert-manager
        echo "DEPLOY CERT-MANAGER STACK"
        ## Add the Helm repository
        helm repo add jetstack https://charts.jetstack.io

        ## Update your local Helm chart repository cache
        helm repo update

        ## Install cert-manager
        helm install \
            cert-manager jetstack/cert-manager \
            --namespace cert-manager \
            --create-namespace \
            --version v1.12.0 \
            --set installCRDs=true       
        sleep 10s 
        kubectl wait --for condition=containersready -n cert-manager pod --all --timeout=300s
    fi
}

function metalLB() {
    if [[ "$NODE_MASTER" == *"$NODE_NAME"* ]]; then
        echo "DEPLOY METALLB STACK"
        # Deploy metallb
        kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml
        #ok=0
        #time_out=0
        echo "Check MetalLB deployment..."
        sleep 10s
        kubectl wait --for condition=containersready -n metallb-system pod --all --timeout=300s
        # while [[ $ok == 0 ]]; do
        #     pods_lb=$(kubectl -n metallb-system get pod | grep speaker | awk '{ print $3}')
        #     for item in "${pods_lb[@]}"; do
        #         if [[ "$item" != *"Running"* ]]; then
        #             ok=0
        #             break
        #         else
        #             ok=1
        #         fi
        #     done
        #     ((time_out++))
        #     sleep 1s
        #     if [[ $time_out -gt 100 ]]; then
        #         break
        #     fi
        # done
        echo "Pods are running!!! Now, waiting for alocate ip addresss pool..."
        sleep 30
        kubectl -n metallb-system apply -f configs/rke2/metallb.yaml
        echo "MetalLB deployment has complete with success!!!"
        # if [[ $ok == 1 ]]; then
        #     kubectl -n metallb-system apply -f configs/rke2/metallb.yaml
        #     echo "MetalLB deployment has complete with success!!!"
        # else
        #     echo "Error!!! MetalLB deployment failed!!!"
        # fi
    fi
}

function longhorn(){
    if [[ "$NODE_MASTER" == *"$NODE_NAME"* ]]; then
        # Deploy longhorn
        echo "DEPLOY LONGHORN STACK"
        ## Create auth for secret \ ingress for access UI
        USER=longhorn
        PASSWORD=longhorn@123456
        echo "${USER}:$(openssl passwd -stdin -apr1 <<<${PASSWORD})" >security/auth

        ## install helm chart longhorn
        helm repo add longhorn https://charts.longhorn.io
        helm repo update
        helm upgrade --install longhorn longhorn/longhorn \
            --namespace longhorn-system \
            --create-namespace \
            --values configs/longhorn/values.yaml
        sleep 10s
        kubectl wait --for condition=containersready -n longhorn-system pod --all --timeout=300s
         # --set defaultSettings.v2DataEngine=true --set persistence.defaultDataLocality="best-effort"
        
        ## create secret
        #kubectl -n longhorn-system create secret generic basic-auth --from-file=security/auth

        ## create ingress
        kubectl -n longhorn-system apply -f configs/longhorn/longhorn-ingress.yml
    fi
}

function rancher(){
    if [[ "$NODE_MASTER" == *"$NODE_NAME"* ]]; then
        # Deploy rancher
        echo "DEPLOY RANCHER STACK"

        ## Add the Rancher Stable Helm Repo
        helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
        helm repo update

        ## Create a namespace for Rancher
        kubectl create namespace cattle-system

        ## Install Rancher using Helm
        helm upgrade -i rancher rancher-stable/rancher \
            --namespace cattle-system \
            --set hostname=rancher.skynet.com.br \
            --set bootstrapPassword=Rancher@123456
        sleep 10s        
        #kubectl wait --for condition=containersready -n cattle-system pod --all --timeout=60s
    fi
    
}

function argocd(){
    if [[ "$NODE_MASTER" == *"$NODE_NAME"* ]]; then
         # Deploy ArgoCD
        echo "DEPLOY ARGOCD STACK"

        ## Create a namespace
        echo "CREATE ARGOCD NAMESPACE"
        kubectl create namespace argocd

        ## Deployment
        echo "DEPLOY ARGOCD PODS"
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        sleep 10s
        kubectl wait --for condition=containersready -n argocd pod --all --timeout=300s

        ## Ingress
        echo "CREATE ARGOCD INGRESS"
        kubectl apply -f configs/argocd/ingress.yaml

        ## Install CLI
        echo "INSTALL ARGOCD CLI"
        if ! command -v argocd &>/dev/null; then
            curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
            install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
            rm argocd-linux-amd64
        fi
    fi
}

# Functio for deployments
function deploy-apps() {
    if [[ "$NODE_MASTER" == *"$NODE_NAME"* ]]; then               
        ## Login in server
        echo "LOGIN IN ARGOCD"
        STATUS=$(curl -Ik --silent https://argocd.skynet.com.br | head -n 1 | awk -F' ' '{print $2}')
        while [ "$STATUS" != 200 ]; do
            clear
            echo "Waiting for argocd stack to be initialized..."
            STATUS=$(curl -Ik --silent https://argocd.skynet.com.br | head -n 1 | awk -F' ' '{print $2}')
            echo "$STATUS"
            sleep 1
        done
        PASS=$(
            kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
            echo
        )
        echo "y" | argocd --insecure login argocd.skynet.com.br \
            --username=admin \
            --password="$PASS" \
            --grpc-web

        ## Save password
        echo "GET ARGOCD INITIAL PASSWORD"
        kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d >security/argocd-password

        ## Register A Cluster To Deploy Apps To
        echo "REGISTER CLUSTER TO DEPLOY APPS IN ARGOCD"
        echo "y" | argocd --insecure cluster add default

        ## Deploy apps from git repository
        echo "DEPLOY APPS IN ARGOCD FROM GIT REPOSITORY"

        ### Create namespace for apps
        kubectl create namespace silvestrini

        ### Set default context for namespace silvestrini
        kubectl config set-context --current --namespace=silvestrini

        ### Create the example 1
        sleep 60
        argocd app create guestbook \
            --repo https://github.com/argoproj/argocd-example-apps.git \
            --path guestbook \
            --dest-server https://kubernetes.default.svc \
            --dest-namespace silvestrini \
            --insecure

        ### Create the example 2 - Helm Charts
        argocd app create helm-guestbook \
            --repo https://github.com/argoproj/argocd-example-apps.git \
            --path helm-guestbook \
            --dest-server https://kubernetes.default.svc \
            --dest-namespace silvestrini \
            --insecure

        ### Create the example 3 - My app - app-silvestrini
        argocd app create app-silvestrini \
            --repo https://github.com/marcossilvestrini/learning-kubernetes.git \
            --path apps/app-silvestrini \
            --dest-server https://kubernetes.default.svc \
            --dest-namespace silvestrini \
            --insecure

        ### Create the example 3 - kube-prometheus stack
        kubectl create ns kube-prometheus
        #kubectl config set-context --current --namespace=kube-prometheus
        helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
        helm repo update
        helm upgrade -i -n kube-prometheus kube-prometheus prometheus-community/kube-prometheus-stack
        # argocd app create kube-prometheus \
        #      --repo https://github.com/marcossilvestrini/learning-kubernetes.git \
        #      --path apps/kube-prometheus \
        #      --dest-server https://kubernetes.default.svc \
        #      --dest-namespace kube-prometheus \
        #      --insecure
        #kubectl replace -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/master/example/prometheus-operator-crd/monitoring.coreos.com_prometheuses.yaml
        
        ### Sync apps
        echo "SYNC APPS IN ARGOCD"
        argocd --insecure app sync app-silvestrini guestbook helm-guestbook

        # ### Update password
        # argocd account update-password \
        #     --current-password "$ARGO_PASS" \
        #     --new-password "Argocd@123456" \
        #     --insecure
    fi
}

# Main
source .bashrc
init
cert-manager
metalLB
longhorn
rancher
argocd
deploy-apps
