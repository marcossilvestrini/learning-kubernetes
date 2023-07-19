#!/bin/bash

<<'MULTILINE-COMMENT'
    Requirments: none
    Description: Script for install and configure rke2  as node\control_palne for labs.
    Author: Marcos Silvestrini
    Date: 27/06/2023
MULTILINE-COMMENT

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
    echo "Distribution is Oracle Linux Server...Congratulations!!!"
else
    echo "This script is available only Oracle Linux Server distributions!!!";exit 1;
fi

# Configure NFS
echo "Set NFS for PV provision..."
mkdir /mnt/nfs
dnf install nfs-utils
systemctl enable rpcbind
systemctl enable nfs-server
cp configs/nfs/exports /etc
dos2unix /etc/exports
chmod 644 /etc/exports
systemctl start rpcbind
systemctl start nfs-server
exportfs -arv 

echo "Install Helm...."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

#  RKE2 Docs

# https://docs.rke2.io/install/quickstart
# https://docs.rke2.io/install/ha
# https://docs.rke2.io/reference/server_config
# https://computingforgeeks.com/deploy-kubernetes-on-rocky-using-rke2/?expand_article=1

# Fix network interface. RKE2 geta etho, but dns is set in eth1. Force eth1 here
cp configs/rke2/rke2-canal.conf /etc/NetworkManager/conf.d 
chmod 644 /etc/NetworkManager/conf.d/rke2-canal.conf
systemctl reload NetworkManager
#systemctl stop NetworkManager

# Create etcd user
useradd -r -c "etcd user" -s /sbin/nologin -M etcd -U

# Set default route for RKE2
ip route add default  via 192.168.0.1 dev eth1

# install server node
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=server sh -
#INSTALL_RKE2_TYPE=server ./scripts/rke2/install.sh

# set first node
if [[ "$NODE_MASTER" == *"$NODE_NAME"* ]]; then
    echo "INSTALL FIRST NODE $(hostname -f)"        
    # Fix error create etcd pod
    if [ -f "/var/lib/rancher/rke2/agent/pod-manifests/etcd.yaml" ]; then
        rm  /var/lib/rancher/rke2/agent/pod-manifests/etcd.yaml     
    fi
    # Set first node
    cp configs/rke2/config-first-node.yaml /etc/rancher/rke2/config.yaml
    chmod 600 /etc/rancher/rke2/config.yaml    
    sed -i "s/ipNode/$IP_NODE/g" /etc/rancher/rke2/config.yaml    

    # enable service
    systemctl enable rke2-server.service

    # start the service
    echo "RESTART RKE2 SERVICE AFTER APPLY [/etc/rancher/rke2/config.yaml]"
    systemctl restart rke2-server.service

    # Create storage class 
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml

    # save first node token 
    TOKEN_NODE=$(cat /var/lib/rancher/rke2/server/node-token)    
    echo "$TOKEN_NODE" > configs/rke2/token-first-node    
    
    # copy the kubeconfig file to share
    cp /etc/rancher/rke2/rke2.yaml configs/kubectl
    sed -i "s/https:\/\/192.168.0.140:6443/https:\/\/rancher.skynet.com.br:6443/g" configs/kubectl/rke2.yaml 

else
    echo "ADD NODE $(hostname -f) IN CLUSTER"       
    
    # Fix error create etcd pod
    if [ -f "/var/lib/rancher/rke2/agent/pod-manifests/etcd.yaml" ]; then
         rm  /var/lib/rancher/rke2/agent/pod-manifests/etcd.yaml     
    fi

    # Add nodes to cluster    
    cp configs/rke2/config-nodes.yaml /etc/rancher/rke2/config.yaml
    chmod 600 /etc/rancher/rke2/config.yaml

    # Get server node token
    TOKEN_NODE=$(cat configs/rke2/token-first-node)
    sed -i "s/tokenNode/$TOKEN_NODE/g" /etc/rancher/rke2/config.yaml    
    sed -i "s/ipNode/$IP_NODE/g" /etc/rancher/rke2/config.yaml    
    
    # enable service
    systemctl enable rke2-server.service

    # start the service
    echo "RESTART RKE2 SERVICE AFTER APPLY [/etc/rancher/rke2/config.yaml]"        
    systemctl restart rke2-server.service
    
fi

# Set kubectl, .bashrc and apply patch for CNI Canal
if [ -d "/var/lib/rancher/rke2/bin" ]; then
    echo "Setting kubectl and profile..."
    
    # Copy kubectl binary to the local user bin folder
    echo "Copy kubectl binary to the local user bin folder"
    cp /var/lib/rancher/rke2/bin/kubectl /usr/local/bin    

    # Install kubecolor
    echo "Download kubecolor"
    wget -q https://github.com/hidetatz/kubecolor/releases/download/v0.0.25/kubecolor_0.0.25_Linux_x86_64.tar.gz
    echo "Extract kubecolor files"
    tar xvfz kubecolor_0.0.25_Linux_x86_64.tar.gz

    echo "Move kubecolor binary to the local user bin folder"
    mv  kubecolor /usr/local/bin    

    echo "Set permissions for kubecolor"
    chmod +x /usr/local/bin/kubecolor  

    echo "Remove kubecolor trash files"
    rm kubecolor_0.0.25_Linux_x86_64.tar.gz LICENSE  README.md

    # Set bash session
    echo "Set .bashrc for user vagrant [configs/commons/.bashrc-ol9-kubernetes --> /home/vagrant/.bashrc]"
    cp -f configs/commons/.bashrc-ol9-kubernetes .bashrc
    dos2unix .bashrc
    
    echo "Set permissions for user vagrant in .bashrc"
    chown vagrant:vagrant .bashrc

    # Set properties for user root
    echo "Set .bashrc for user root [/home/vagrant --> /root/.bashrc]"
    cp -f .bashrc /root/

    # source .bashrc
    echo "Source /home/vagrant/.bashrc"
    source .bashrc    
fi

# Deployment storage,dashboard and others pods
if [[ "$NODE_MASTER" == *"$NODE_NAME"* ]]; then       

    echo "Deploy Rancher Local Path Provisioner..."
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml

    # Set default Storage Class    
    echo "Set default Storage Class for NFS..."
    kubectl patch storageclass nfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

    # Deployment dashboard    
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

    # Create access token for dashboard
    kubectl create token admin-user -n kubernetes-dashboard > security/dashboard-token
    
fi

# Check the health of the deployment by running a status command:
#kubectl get componentstatuses
#kubectl get nodes

# follow the logs, if you like
# journalctl -u rke2-server -f