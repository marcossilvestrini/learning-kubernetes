#!/bin/bash

<<'MULTILINE-COMMENT'
    Requirments: none
    Description: Script for install and configure rke2 as node\control_palne for labs.
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
NODE_MASTER="debian-server01"
NODE_NAME=$(hostname)
IP=$(hostname -i)

# Check if distribution is Debian
if [[ "$DISTRO" == *"Debian"* ]]; then
    echo "Distribution is Debian...Congratulations!!!"
else
    echo "This script is available only Debian distributions!!!";exit 1;
fi

# https://docs.rke2.io/install/quickstart
# https://docs.rke2.io/install/ha
# https://docs.rke2.io/reference/server_config


# Stop network manager
systemctl stop NetworkManager
systemctl disable NetworkManager

# uninstall old installation
sh ./scripts/rke2/uninstall-rke2.sh

# install server node
curl -sfL https://get.rke2.io | sh -

# enable service
systemctl enable rke2-server.service

# start the service
systemctl start rke2-server.service

# set first node
mkdir -p /etc/rancher/rke2

echo "INSTALL NODE $(hostname -f)"
cp configs/rke2/config-first-node.yaml /etc/rancher/rke2/config.yaml
chmod 600 /etc/rancher/rke2/config.yaml
TOKEN_NODE=$(cat /var/lib/rancher/rke2/server/node-token)
sed -i "s/tokenNode/$TOKEN_NODE/g" /etc/rancher/rke2/config.yaml
echo "$TOKEN_NODE" > configs/rke2/token-first-node

# stop the service
systemctl stop rke2-server.service

# reset cluster - fix some errors in up service
rke2 server --cluster-reset --node-ip "$IP" --node-external-ip "$IP"  --advertise-address "$IP"


# Copy kubectl to the local user bin folder:
cp /var/lib/rancher/rke2/bin/kubectl /usr/local/bin

# Add kubectl to the PATH variable on the first server:
#export PATH=$PATH:/opt/rke2/bin:/var/lib/rancher/rke2/bin

# Export the kubeconfig file on the first server:
# export KUBECONFIG=/etc/rancher/rke2/rke2.yaml

# Check the health of the deployment by running a status command:
#kubectl get componentstatuses
#kubectl get nodes

# follow the logs, if you like
# journalctl -u rke2-server -f