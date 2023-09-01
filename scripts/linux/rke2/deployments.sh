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
    ARGOCD_USER="skynet"
    ARGOCD_PASS="Skynet@123456"

    # Check if distribution is RPM-->Oracle Linux Server
    if [[ "$DISTRO" == *"Oracle"* ]]; then
        echo "CHECK IF DISTRIBUTION IS ORACLE..."
        echo "CONGRATULATIONS, YOUR DISTRO SO GOOD!"
    else
        echo "THIS SCRIPT IS AVAILABLE ONLY ORACLE LINUX SERVER DISTRIBUTIONS!!!"
        exit 1
    fi
}

function deploy-cert-manager() {
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
}

function deploy-metalLB() {
    echo "DEPLOY METALLB STACK"
    # Deploy metallb
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml
    #ok=0
    #time_out=0
    echo "Check MetalLB deployment..."
    sleep 10s
    kubectl wait --for condition=containersready -n metallb-system pod --all --timeout=300s

    echo "Pods are running!!! Now, waiting for alocate ip addresss pool..."
    sleep 30
    kubectl -n metallb-system apply -f configs/rke2/metallb.yaml
    echo "MetalLB deployment has complete with success!!!"
}

function deploy-longhorn() {
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
}

function deploy-rancher() {
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
}

function deploy-argocd() {
    # Deploy ArgoCD
    echo "DEPLOY ARGOCD STACK"

    ## Create a namespace
    echo "CREATE ARGOCD NAMESPACE"
    kubectl create namespace argocd

    ## Ingress
    echo "CREATE ARGOCD INGRESS"
    kubectl apply -f configs/argocd/ingress.yaml

    ## Deployment
    echo "DEPLOY ARGOCD PODS"
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    sleep 10s
    echo "Waiting for deployment argocd to complete..."
    kubectl wait --for condition=containersready -n argocd pod --all --timeout=900s
    STATUS=$(curl -Ik --silent https://argocd.skynet.com.br | head -n 1 | awk -F' ' '{print $2}')
    while [ "$STATUS" != 200 ]; do
        clear
        echo "Waiting for argocd stack to be initialized..."
        STATUS=$(curl -Ik --silent https://argocd.skynet.com.br | head -n 1 | awk -F' ' '{print $2}')
        echo "$STATUS"
        sleep 1
    done

    ## Install CLI
    echo "INSTALL ARGOCD CLI"
    if ! command -v argocd &>/dev/null; then
        curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
        rm argocd-linux-amd64
    fi

    ## Save password
    echo "GET ARGOCD INITIAL PASSWORD"
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d >security/argocd-password

    ## Create argocd user
    echo "CREATE NEW ARGOCD USER FOR DEPLOYMENT"
    PASS=$(
        kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
        echo
    )
    login-argocd
    kubectl delete -f configs/argocd/argocd-cm.yml
    kubectl apply -f configs/argocd/argocd-cm.yml
    argocd account update-password --account "$ARGOCD_USER" --current-password "$PASS" --new-password "$ARGOCD_PASS"    
}

function login-argcd() {
    # Login in server
    echo "LOGIN IN ARGOCD"

    PASS=$(
        kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
        echo
    )
    echo "y" | argocd --insecure login argocd.skynet.com.br \
        --username=admin \
        --password="$PASS" \
        --grpc-web
}

function update-argcd-password(){
    echo "UPDATE ARGOCD PASSWORD"
    # ### Update password
    # argocd account update-password \
    #     --current-password "$ARGO_PASS" \
    #     --new-password "Argocd@123456" \
    #     --insecure
}

function deploy-kube-prometheus() {
    export ARGOCD_EXEC_TIMEOUT="900s"
    login-argcd
    echo "DEPLOY KUBE-PROMETHEUS-STACK"

    # Create argocd aplication
    echo "CREATE ARGOCD APP KUBE-PROMETHEUS-STACK"
    argocd app create kube-prometheus \
        --repo https://github.com/prometheus-community/helm-charts.git \
        --path charts/kube-prometheus-stack/ \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace kube-prometheus \
        --insecure

    # Set argocd app with some options
    argocd app set kube-prometheus --sync-option ApplyOutOfSyncOnly=true
    argocd app set kube-prometheus --sync-option CreateNamespace=true
    argocd app set kube-prometheus --sync-option ServerSideApply=true

    # Sync app
    echo "SYNC APP KUBE-PROMETHEUS-STACK IN ARGOCD"
    argocd app sync --insecure kube-prometheus

    # Create ingress
    kubectl apply -f apps/kube-prometheus/ingress.yaml
}

function deploy-app-examples() {
    login-argcd
    echo "DEPLOY APPS EXAMPLES"

    # Create argocd aplication
    echo "CREATE ARGOCD APP EXAMPLES"

    ### Create the example 1
    argocd app create guestbook \
        --repo https://github.com/argoproj/argocd-example-apps.git \
        --path guestbook \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace examples \
        --insecure
    argocd app set guestbook --sync-option ApplyOutOfSyncOnly=true
    argocd app set guestbook --sync-option CreateNamespace=true
    argocd app set guestbook --sync-option ServerSideApply=true

    ### Create the example 2 - Helm Charts
    argocd app create helm-guestbook \
        --repo https://github.com/argoproj/argocd-example-apps.git \
        --path helm-guestbook \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace examples \
        --insecure
    argocd app set helm-guestbook --sync-option ApplyOutOfSyncOnly=true
    argocd app set helm-guestbook --sync-option CreateNamespace=true
    argocd app set helm-guestbook --sync-option ServerSideApply=true

    # Sync app
    echo "SYNC APP EXAMPLES"
    argocd app sync --insecure guestbook helm-guestbook
}

function deploy-app-silvestrini() {
    login-argcd
    echo "DEPLOY MY APPS IN ARGOCD"    
    echo "CREATE ARGOCD APP APP-SILVESTRINI"
    argocd app create app-silvestrini \
        --repo https://github.com/marcossilvestrini/learning-kubernetes.git \
        --path apps/app-silvestrini \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace silvestrini \
        --insecure
    argocd app set app-silvestrini --sync-option ApplyOutOfSyncOnly=true
    argocd app set app-silvestrini --sync-option CreateNamespace=true
    argocd app set app-silvestrini --sync-option ServerSideApply=true

    # Sync apps
    echo "SYNC APP IN ARGOCD"
    argocd app sync --insecure app-silvestrini
}

function deploy-openebs-localpv() {
    login-argcd    
    echo "DEPLOY OPENEBS LOCALPV"

    # OpenEBS localpv-hostpath
    echo "CREATE ARGOCD APP APP-SILVESTRINI"
    argocd app create openebs-localpv-hostpath \
        --repo https://github.com/marcossilvestrini/learning-kubernetes.git \
        --path openebs/dynamic-localpv-hostpath \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace openebs-localpv-hostpath \
        --insecure    
    argocd app set openebs-localpv-hostpath --sync-option ApplyOutOfSyncOnly=true
    argocd app set openebs-localpv-hostpath --sync-option CreateNamespace=true
    argocd app set openebs-localpv-hostpath --sync-option ServerSideApply=true
    echo "SYNC APP IN ARGOCD"
    argocd app sync --insecure openebs-localpv-hostpath
}

function deploy-gitlab() {
    echo "DEPLOY GITLAB STACK"
    kubectl create namespace gitlab
    helm repo add gitlab https://charts.gitlab.io/
    helm repo update
    helm upgrade --install gitlab gitlab/gitlab \
        --set certmanager.installCRDs=false \
        --namespace gitlab \
        --timeout 600s \
        --set global.hosts.domain=skynet.com.br \
        --set global.edition=ce \
        --set certmanager-issuer.email=marcos.silvestrini@gmail.com \
        --set postgresql.image.tag=13.6.0 \
        --set gitlab.migrations.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-rails-ce \
        --set gitlab.sidekiq.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ce \
        --set gitlab.unicorn.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-unicorn-ce \
        --set gitlab.unicorn.workhorse.image=registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ce
    ## Save password
    kubectl -n gitlab get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode >security/gitlab
}

function delete-all-apps(){
    login-argcd
    argocd  app delete -y openebs-localpv-hostpath kube-prometheus guestbook helm-guestbook app-silvestrini
}

# Main
source .bashrc
init
deploy-cert-manager
deploy-metalLB
deploy-longhorn
deploy-rancher
deploy-argocd
deploy-app-examples
deploy-app-silvestrini
deploy-kube-prometheus
#deploy-openebs-localpv
#deploy-gitlab
#delete-all-apps
