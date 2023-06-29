#!/bin/bash

<<'MULTILINE-COMMENT'
    Requirments: none
    Description: Script for install and configure Kubernetes Cluster with kube-adm for labs.
    Author: Marcos Silvestrini
    Date: 29/06/2023
MULTILINE-COMMENT

# Set language/locale and encoding
export LANG=C

# Set workdir
WORKDIR="/home/vagrant"
cd $WORKDIR || exit

# Variables
DISTRO=$(cat /etc/*release | grep -ws NAME=)


# Check if distribution is Debian
if [[ "$DISTRO" == *"Debian"* ]]; then
    echo "Distribution is Debian...Congratulations!!!"
else
    echo "This script is available only Debian distributions!!!";exit 1;
fi

