#!/bin/bash

<<'MULTILINE-COMMENT'
    Requirments: none
    Description: Script for install and configure rke2 as agent\worker for labs.
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
TOKEN_NODE=$(cat configs/rke2/token-first-node)

# Check if distribution is RPM-->Oracle Linux Server
if [[ "$DISTRO" == *"Oracle"* ]]; then
    echo "Distribution is Oracle Linux Server...Congratulations!!!"
else
    echo "This script is available only Oracle Linux Server distributions!!!";exit 1;
fi

# https://docs.rke2.io/install/quickstart
# https://docs.rke2.io/install/ha
# https://docs.rke2.io/reference/server_config

# Fix network interface. RKE2 geta etho, but dns is set in eth1. Force eth1 here
#cp configs/rke2/rke2-canal.conf /etc/NetworkManager/conf.d 
#chmod 644 /etc/NetworkManager/conf.d/rke2-canal.conf
#systemctl restart NetworkManager
systemctl stop NetworkManager

# Create etcd user
useradd -r -c "etcd user" -s /sbin/nologin -M etcd -U

# Set default route for RKE2
ip route add default  via 192.168.0.1 dev eth1

# install server node
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -

# set agent
mkdir -p /etc/rancher/rke2
cp configs/rke2/config-agent.yaml /etc/rancher/rke2/config.yaml
chmod 600 /etc/rancher/rke2/config.yaml
sed -i "s/tokenNode/$TOKEN_NODE/g" /etc/rancher/rke2/config.yaml

# enable service
systemctl enable rke2-agent.service

# start the service
systemctl restart rke2-agent.service

# Copy kubectl to the local user bin folder:
if [ -d "/var/lib/rancher/rke2/bin" ]; then
    
    # Copy kubectl binary to the local user bin folder
    cp /var/lib/rancher/rke2/bin/kubectl /usr/local/bin    
    
    # Set bash session
    cp -f configs/commons/.bashrc-ol9-kubernetes .bashrc
    dos2unix .bashrc
    chown vagrant:vagrant .bashrc

    # Set properties for user root
    cp -f .bashrc /root/
    source .bashrc

    # Set canal interface 
    cp configs/rke2/rke2-canal-config.yaml /var/lib/rancher/rke2/server/manifests/
    
    # After that, please restart the canal daemonset to use the newer config by executing:
    kubectl rollout restart ds rke2-canal -n kube-system
fi

# # follow the logs, if you like
# # journalctl -u rke2-server -f