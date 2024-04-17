#!/bin/bash

<<'MULTILINE-COMMENT'
    Requirments: none
    Description: Script for install and configure Saltstack
    Author: Marcos Silvestrini
    Date: 18/09/2023
MULTILINE-COMMENT

# functions
function init() {
    # Set language/locale and encoding
    export LANG=C

    # Set workdir
    WORKDIR="/home/vagrant"
    cd $WORKDIR || exit

    # Variables
    DISTRO=$(cat /etc/*release | grep -ws NAME=)
    SALT_MASTER="managment.skynet.com.br"
    INSTANCE_NAME=$(hostname)

    # Check if distribution is RPM-->Oracle Linux Server
    if [[ "$DISTRO" == *"Oracle"* ]]; then
        echo "CHECK IF DISTRIBUTION IS ORACLE..."
        echo "CONGRATULATIONS, YOUR DISTRO SO GOOD!"
    elif [[ "$DISTRO" == *"Rocky"* ]]; then
        echo "CHECK IF DISTRIBUTION IS ROCKY LINUX..."
        echo "CONGRATULATIONS, YOUR DISTRO SO GOOD!"
    else
        echo "THIS SCRIPT IS AVAILABLE ONLY ORACLE LINUX SERVER DISTRIBUTIONS!!!"
        exit 1
    fi
}

function install-salt() {
    # Run the following commands to install the Salt Project repository and key
    rpm --import https://repo.saltproject.io/salt/py3/fedora/38/x86_64/SALT-PROJECT-GPG-PUBKEY-2023.pub
    curl -fsSL https://repo.saltproject.io/salt/py3/fedora/38/x86_64/latest.repo | tee /etc/yum.repos.d/salt.repo

    # clear cache
    dnf clean expire-cache

    # Install the salt-minion, salt-master, or other Salt components
    if [[ "$SALT_MASTER" == *"$INSTANCE_NAME"* ]]; then
        echo "CONFIGURE SALT MASTER IN $(hostname -f)"

        # Create salt directories
        mkdir -p /srv/{salt,pillar}

        # Instal saltsatck
        dnf install -y salt-master        
        dnf install -y salt-ssh
        dnf install -y salt-syndic
        dnf install -y salt-cloud
        dnf install -y salt-api

        # Set Salt master
        MASTER_IP=$(hostname -i)
        echo "$MASTER_IP" > configs/salt/ipmaster
        cp configs/salt/master /etc/salt/master
        cp configs/salt/network.conf /etc/salt/master.d/network.conf
        sed -i "s/IP_MASTER/$MASTER_IP/g" /etc/salt/master.d/network.conf
        
        # Start services
        systemctl enable salt-master && systemctl start salt-master        
        systemctl enable salt-syndic && systemctl start salt-syndic
        systemctl enable salt-api && systemctl start salt-api

        # Waiting for servevices up
        sleep 30

        # Accept minions keys
        salt-key -y -A

        # Test connections with minions
        #salt -t 30 '*' test.ping

    else
        echo "CONFIGURE SALT MINION IN $(hostname -f)"        
        # Instal salt minion
        #dnf install -y salt-minion

        # Set Salt master
        MASTER_IP=$(cat configs/salt/ipmaster)
        cp configs/salt/minion-master.conf /etc/salt/minion.d/master.conf
        sed -i "s/IP_MASTER/$MASTER_IP/g" /etc/salt/minion.d/master.conf

        # Start service
        systemctl enable salt-minion && systemctl restart salt-minion
    fi
}

# Main
init
install-salt
