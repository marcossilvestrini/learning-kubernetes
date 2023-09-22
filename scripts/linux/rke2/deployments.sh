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

function deploy-argocd() {
    # Deploy ArgoCD
    echo "DEPLOY ARGOCD STACK"

    ## Create a namespace
    echo "CREATE ARGOCD NAMESPACE"
    kubectl create namespace argocd

    ## Ingress
    echo "CREATE ARGOCD INGRESS"
    kubectl apply -f apps/argocd/ingress.yaml

    ## Deployment
    echo "DEPLOY ARGOCD PODS"
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    echo "Waiting for deployment argocd to complete..."
    sleep 10s    
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
    echo "Waiting for deployment cert-manager to complete..."
    sleep 10s
    kubectl wait --for condition=containersready -n cert-manager pod --all --timeout=600s
}

function deploy-metalLB() {
    echo "DEPLOY METALLB STACK"
    # Deploy metallb
    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.10/config/manifests/metallb-native.yaml
    #ok=0
    #time_out=0
    echo "Waiting for deployment metallb to complete..."
    sleep 10s
    kubectl wait --for condition=containersready -n metallb-system pod --all --timeout=600s

    # echo "Pods are running!!! Now, waiting for alocate ip addresss pool..."
    # sleep 30
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
        --values charts/longhorn/values.yaml
    echo "Waiting for deployment longhorn to complete..."
    sleep 10s
    kubectl wait --for condition=containersready -n longhorn-system pod --all --timeout=900s
    # --set defaultSettings.v2DataEngine=true --set persistence.defaultDataLocality="best-effort"

    ## create secret
    #kubectl -n longhorn-system create secret generic basic-auth --from-file=security/auth

    ## create ingress
    kubectl -n longhorn-system apply -f charts/longhorn/longhorn-ingress.yml
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
    echo "Waiting for deployment rancher to complete..."
    sleep 10s
    #kubectl wait --for condition=containersready -n cattle-system pod --all --timeout=60s
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

    # Waiting for deploy
    echo "Waiting for deployment kube-prometheus to complete..."
    argocd app wait kube-prometheus --health --timeout 300

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

    # Waiting for deploy
    echo "Waiting for deployment guestbook to complete..."
    argocd app wait guestbook --health --timeout 300 
    argocd app wait helm-guestbook --health --timeout 300 
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

    # Waiting for deploy
    echo "Waiting for deployment app-silvestrini to complete..."
    argocd app wait app-silvestrini --health --timeout 300 
}

function deploy-chart-silvestrini() {
    login-argcd
    echo "DEPLOY MY APPS IN ARGOCD"    
    echo "CREATE ARGOCD APP APP-SILVESTRINI"
    argocd app create app-silvestrini \
        --repo https://github.com/marcossilvestrini/learning-kubernetes.git \
        --path charts/app-silvestrini \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace silvestrini \
        --insecure
    argocd app set app-silvestrini --sync-option ApplyOutOfSyncOnly=true
    argocd app set app-silvestrini --sync-option CreateNamespace=true
    argocd app set app-silvestrini --sync-option ServerSideApply=true

    # Sync apps
    echo "SYNC APP IN ARGOCD"
    argocd app sync --insecure app-silvestrini

    # Waiting for deploy
    echo "Waiting for deployment app-silvestrini to complete..."
    argocd app wait app-silvestrini --health --timeout 300 
}

function deploy-openebs-localpv() {
    login-argcd    
    echo "DEPLOY OPENEBS LOCALPV"

    # OpenEBS localpv-hostpath
    echo "CREATE ARGOCD APP OPENEBS LOCALPV "
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

    # Waiting for deploy
    echo "Waiting for deployment openebs-localpv to complete..."
    argocd app wait  openebs-localpv-hostpath --health --timeout 300 
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

function deploy-netbox() {
    login-argcd
    echo "DEPLOY NETBOX IN ARGOCD"    
    echo "CREATE ARGOCD APP NETBOX"
    argocd app create netbox \
        --repo https://github.com/bootc/netbox-chart.git \
        --dest-server https://kubernetes.default.svc \
        --dest-namespace netbox \
        --insecure
    
    # Set app preferences in argocd
    argocd app set netbox --values values.yaml
    argocd app set netbox --sync-option ApplyOutOfSyncOnly=true
    argocd app set netbox --sync-option CreateNamespace=true
    argocd app set netbox --sync-option ServerSideApply=true

    # Sync apps
    echo "SYNC APP IN ARGOCD"
    argocd app sync --insecure netbox

    # Waiting for deploy
    echo "Waiting for deployment netbox to complete..."
    argocd app wait netbox --health --timeout 300 
}

function delete-all-apps(){
    login-argcd
    argocd  app delete -y openebs-localpv-hostpath kube-prometheus guestbook helm-guestbook app-silvestrini
}

# Main
source .bashrc
init
deploy-argocd
deploy-cert-manager
deploy-metalLB
deploy-longhorn
deploy-rancher
deploy-app-examples
deploy-chart-silvestrini
deploy-kube-prometheus
#deploy-openebs-localpv
#deploy-gitlab
#delete-all-apps
