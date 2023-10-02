#!/bin/bash

<<'MULTILINE-COMMENT'
    Requirments: none
    Description: Script up api update-nginx-config
    Author: Marcos Silvestrini
    Date: 26/09/2023
MULTILINE-COMMENT

export LANG=C

cd /home/vagrant || exit

# Install required packages for api api-update-nginx-config.py
pip3 install flask

# Up api
#echo -e "\n" | nohup python3 api/load-balance/api-update-nginx-config.py &
nohup python3 api/load-balance/api-update-nginx-config.py < /dev/null > /var/log/api-update-nginx-config.log 2>&1 &
# python3 api/load-balance/api-update-nginx-config.py
