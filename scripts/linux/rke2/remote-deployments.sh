#!/bin/bash

<<'MULTILINE-COMMENT'
    Requirments: none
    Description: Script for deployments apps in rke2 cluster for labs.
    Author: Marcos Silvestrini
    Date: 21/07/2023
MULTILINE-COMMENT

sshpass -p 'vagrant' ssh -o StrictHostKeyChecking=no vagrant@$NODE_MASTER -l vagrant sudo ./scripts/rke2/deployments.sh