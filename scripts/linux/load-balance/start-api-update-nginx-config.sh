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
pip install flask

# Up api
echo -e "\n" | nohup python3 api/load-balance/api-update-nginx-config.py &
# python3 api/load-balance/api-update-nginx-config.py
