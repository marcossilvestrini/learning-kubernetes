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
function init(){
    # Set language/locale and encoding
    export LANG=C
    
    # Set workdir
    WORKDIR="/home/vagrant"
    cd $WORKDIR || exit
   
    # Variables
    DISTRO=$(cat /etc/*release | grep -ws NAME=)
    NODE_MASTER="control-plane01"
    NODE_NAME=$(hostname)
    IP_NODE=$(hostname -i)
    
    # Check if distribution is RPM-->Oracle Linux Server
    if [[ "$DISTRO" == *"Oracle"* ]]; then
        echo "CHECK IF DISTRIBUTION IS ORACLE..."
        echo "CONGRATULATIONS, YOUR DISTRO SO GOOD!"
    else
        echo "THIS SCRIPT IS AVAILABLE ONLY ORACLE LINUX SERVER DISTRIBUTIONS!!!";exit 1;
    fi
    
    # Get token
    if [[ "$NODE_NAME" == *"worker"* ]]; then
        echo "GET CLUSTER TOKEN..."
        TOKEN_NODE=$(cat configs/rke2/token-first-node)
    fi
}

function deployments(){    
    if [[ "$NODE_MASTER" == *"$NODE_NAME"* ]]; then
        
        # Deploy cert-manager

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

        # Deploy rancher
        
        ## Add the Rancher Stable Helm Repo
        helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
        
        ## Create a namespace for Rancher
        kubectl create namespace cattle-system
        
        ## Install Rancher using Helm
        helm install rancher rancher-stable/rancher \
        --namespace cattle-system \
        --set hostname=rancher.skynet.com.br \
        --set bootstrapPassword=Rancher@123456
        
        # Deploy ArgoCD
        
        ## Create a namespace
        kubectl create namespace argocd
        
        ## Deployment
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        ## Ingress
        kubectl apply  -f configs/argocd/ingress.yaml
        
        ## Get password
        kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > security/argocd-password
        
        ## Install CLI
        curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
        rm argocd-linux-amd64
        
        ## Login in server
        until argocd login argocd.skynet.com.br \
        --username admin \
        --password $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo) \
        --insecure --grpc-web; do : ; done
        
        ## Register A Cluster To Deploy Apps To
        echo "y"|argocd cluster add default
        
        ## Create An Application From A Git Repository
        
        ### First we need to set the current namespace to argocd running the following command:
        kubectl config set-context --current --namespace=argocd
        
        ### Create the example 1
        argocd app create guestbook \
        --repo https://github.com/argoproj/argocd-example-apps.git \
        --path guestbook \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace default

        ### Create the example 2 - Helm Charts
        argocd app create helm-guestbook \
            --repo https://github.com/argoproj/argocd-example-apps.git \
            --path helm-guestbook \
            --dest-server https://kubernetes.default.svc \
            --dest-namespace default    

        ### Create the example 3 - My app - app-silvestrini
        cp -R apps/app-silvestrini/images /mnt/nfs/app-silvestrini
        cp apps/app-silvestrini/index.html /mnt/nfs/app-silvestrini
        argocd app create app-silvestrini \
            --repo https://github.com/marcossilvestrini/learning-kubernetes.git \
            --path apps/app-silvestrini \
            --dest-server https://kubernetes.default.svc \
            --dest-namespace default            
    fi
}

# Main
source .bashrc
init
deployments