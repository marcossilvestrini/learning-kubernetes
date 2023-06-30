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

# Check if distribution is Debian
if [[ "$DISTRO" == *"Rock"* ]]; then
    echo "Distribution is Debian...Congratulations!!!"
else
    echo "This script is available only Rock Linux distributions!!!";exit 1;
fi

# https://docs.rke2.io/install/quickstart
# https://docs.rke2.io/install/ha
# https://docs.rke2.io/reference/server_config
# https://computingforgeeks.com/deploy-kubernetes-on-rocky-using-rke2/?expand_article=1

# install server node
#curl -sfL https://get.rke2.io | sh -
INSTALL_RKE2_TYPE=server ./scripts/rke2/install.sh


# Fix network interface. RKE2 geta etho, but dns is set in eth1. Force eth1 here
cp configs/rke2/rke2-canal.conf /etc/NetworkManager/conf.d 
chmod 644 /etc/NetworkManager/conf.d/rke2-canal.conf
#systemctl reload NetworkManager
#systemctl restart NetworkManager
#cp configs/rke2/rke2-fix-network.yaml /var/lib/rancher/rke2/server/manifests
#chmod 644 /var/lib/rancher/rke2/server/manifests/rke2-fix-network.yaml

# set first node
if [[ "$NODE_MASTER" == *"$NODE_NAME"* ]]; then
    echo "INSTALL FIRST NODE $(hostname -f)"    
    # Set first node
    #rm  /var/lib/rancher/rke2/agent/pod-manifests/etcd.yaml 
    cp configs/rke2/config-first-node.yaml /etc/rancher/rke2/config.yaml
    chmod 600 /etc/rancher/rke2/config.yaml    

    # start the service
    systemctl start rke2-server.service

    # enable service
    systemctl enable rke2-server.service

    # save first node token 
    TOKEN_NODE=$(cat /var/lib/rancher/rke2/server/node-token)
    #sed -i "s/tokenNode/$TOKEN_NODE/g" /etc/rancher/rke2/config.yaml
    echo "$TOKEN_NODE" > configs/rke2/token-first-node    
else
    echo "ADD NODE $(hostname -f) IN CLUSTER"
    # Add nodes to cluster
    #rm  /var/lib/rancher/rke2/agent/pod-manifests/etcd.yaml 
    cp configs/rke2/config-nodes.yaml /etc/rancher/rke2/config.yaml
    chmod 600 /etc/rancher/rke2/config.yaml
    # Get server node token
    TOKEN_NODE=$(cat configs/rke2/token-first-node)
    sed -i "s/tokenNode/$TOKEN_NODE/g" /etc/rancher/rke2/config.yaml    

    # start the service
    systemctl start rke2-server.service

    # enable service
    systemctl enable rke2-server.service
fi

# Copy kubectl to the local user bin folder:
cp /var/lib/rancher/rke2/bin/kubectl /usr/local/bin

# Add kubectl to the PATH variable on the first server:
export PATH=$PATH:/opt/rke2/bin:/var/lib/rancher/rke2/bin

# Export the kubeconfig file on the first server:
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml

# set .bashrc
# Set bash session
cp -f configs/commons/.bashrc-rock-kubernetes .bashrc
dos2unix .bashrc
chown vagrant:vagrant .bashrc

# Set properties for user root
cp -f .bashrc .vimrc /root/

# Check the health of the deployment by running a status command:
#kubectl get componentstatuses
#kubectl get nodes

# follow the logs, if you like
# journalctl -u rke2-server -f