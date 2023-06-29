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

# Check if distribution is Debian
if [[ "$DISTRO" == *"Debian"* ]]; then
    echo "Distribution is Debian...Congratulations!!!"
else
    echo "This script is available only Debian distributions!!!";exit 1;
fi

# https://docs.rke2.io/install/quickstart
# https://docs.rke2.io/install/ha
# https://docs.rke2.io/reference/server_config

# install server node
curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE="agent" sh -

# set agent
mkdir -p /etc/rancher/rke2
cp configs/rke2/config-agent.yaml /etc/rancher/rke2/config.yaml
chmod 600 /etc/rancher/rke2/config.yaml
TOKEN_NODE=$(cat configs/rke2/token-first-node)
sed -i "s/tokenNode/$TOKEN_NODE/g" /etc/rancher/rke2/config.yaml

# enable service
systemctl enable rke2-server.service

# start the service
systemctl start rke2-server.service

# # follow the logs, if you like
# # journalctl -u rke2-server -f