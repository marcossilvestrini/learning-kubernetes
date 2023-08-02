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
    
    # Check if distribution is RPM-->Oracle Linux Server
    if [[ "$DISTRO" == *"Oracle"* ]]; then
        echo "CHECK IF DISTRIBUTION IS ORACLE..."
        echo "CONGRATULATIONS, YOUR DISTRO SO GOOD!"
    else
        echo "THIS SCRIPT IS AVAILABLE ONLY ORACLE LINUX SERVER DISTRIBUTIONS!!!";exit 1;
    fi   
}

function deployments(){    
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

        # Deploy rancher
        echo "DEPLOY RANCHER STACK"
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
        echo "DEPLOY ARGOCD STACK"
        
        ## Create a namespace
        echo "CREATE ARGOCD NAMESPACE"
        kubectl create namespace argocd
        
        ## Deployment
        echo "DEPLOY ARGOCD PODS"
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        ## Ingress
        echo "CREATE ARGOCD INGRESS"
        kubectl apply  -f configs/argocd/ingress.yaml
        
        ## Install CLI
        echo "INSTALL ARGOCD CLI"
        if ! command -v argocd &> /dev/null
        then
            curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
            install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
            rm argocd-linux-amd64
        fi
        ## Login in server
        echo "LOGIN IN ARGOCD"   
        STATUS=$(curl -Ik --silent https://argocd.skynet.com.br | head -n 1 | awk -F' ' '{print $2}')
        while [ "$STATUS" != 200 ]
        do 
            clear
            echo "Waiting for argocd stack to be initialized..."                        
            STATUS=$(curl -Ik --silent https://argocd.skynet.com.br | head -n 1 | awk -F' ' '{print $2}')
            echo "$STATUS"
            sleep 1s            
        done                 
        PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo)        
        echo "y" | argocd --insecure login  argocd.skynet.com.br \
            --username=admin \
            --password="$PASS" \
            --grpc-web
            
        ## Save password 
        echo "GET ARGOCD INITIAL PASSWORD"            
        kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > security/argocd-password
        
        ## Register A Cluster To Deploy Apps To
        echo "REGISTER CLUSTER TO DEPLOY APPS IN ARGOCD"
        echo "y"|argocd --insecure cluster add default
        
        ## Deploy apps from git repository
        echo "DEPLOY APPS IN ARGOCD FROM GIT REPOSITORY"
        
        ### Create namespace for apps
        kubectl create namespace silvestrini

        ### Set default context for namespace silvestrini
        kubectl config set-context --current --namespace=silvestrini
        
        ### Create the example 1
        sleep 20        
        argocd --insecure app create guestbook \
            --repo https://github.com/argoproj/argocd-example-apps.git \
            --path guestbook \
            --dest-server https://kubernetes.default.svc \
            --dest-namespace silvestrini
            

        ### Create the example 2 - Helm Charts
        argocd app create helm-guestbook \
            --repo https://github.com/argoproj/argocd-example-apps.git \
            --path helm-guestbook \
            --dest-server https://kubernetes.default.svc \
            --dest-namespace silvestrini    

        ### Create the example 3 - My app - app-silvestrini        
        argocd app create app-silvestrini \
            --repo https://github.com/marcossilvestrini/learning-kubernetes.git \
            --path apps/app-silvestrini \
            --dest-server https://kubernetes.default.svc \
            --dest-namespace silvestrini \
            --insecure     
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
deployments