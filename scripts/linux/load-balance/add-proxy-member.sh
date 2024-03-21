#!/bin/bash

<<'MULTILINE-COMMENT'
    Requirments: none
    Description: Script for add new members in config of proxy NGINX
    Author: Marcos Silvestrini
    Date: 26/09/2023
MULTILINE-COMMENT

export LANG=C

cd /home/vagrant || exit

function add_member_nigix() {
    # Check if the correct number of arguments has been provided
    if [ "$#" -ne 5 ]; then
        echo "Usage: $0 upstream server port max_fails fail_timeout"
        return
    fi

    # Input parameters
    upstream="$1"
    server="$2"
    port="$3"
    max_fails="$4"
    fail_timeout="$5"

    # Check if the Nginx configuration file exists
    nginx_conf="/etc/nginx/nginx.conf" # Change the path as needed
    if [ ! -f "$nginx_conf" ]; then
        echo "Nginx configuration file not found: $nginx_conf"
        return
    fi

    # Check if upstream server is available
    if grep -q "upstream $upstream" "$nginx_conf"; then
        echo "Upstream valid: $upstream"
    else
        echo "Upstream not found: $upstream"
        return
    fi

    # Check if the member already exists in the configuration file
    if grep -q "server $server:$port max_fails=$max_fails fail_timeout=$fail_timeout;" "$nginx_conf"; then
        echo "The member already exists in the configuration file."
        return
    fi
    # Add the new member to the configuration file using sed
    sed -i "/upstream $upstream {/a \        server $server:$port max_fails=$max_fails fail_timeout=$fail_timeout;" "$nginx_conf"

    # Reload Nginx to apply the changes
    systemctl reload nginx

    echo "New member successfully added to upstream $upstream."
}

# Use
# source add-member-nigix.sh

# pool rke2_backend
# add_member_nigix rke2_backend 192.168.0.141 9345 3 6s
# add_member_nigix rke2_backend 192.168.0.142 9345 3 6s

# # pool rke2_api
# add_member_nigix rke2_api 192.168.0.141 6443 3 6s
# add_member_nigix rke2_api 192.168.0.142 6443 3 6s

# # pool rke2_etcd_client
# add_member_nigix rke2_etcd_client 192.168.0.141 2379 3 6s
# add_member_nigix rke2_etcd_client 192.168.0.142 2379 3 6s

# # pool rke2_etcd_peer
# add_member_nigix rke2_etcd_peer 192.168.0.141 2380 3 6s
# add_member_nigix rke2_etcd_peer 192.168.0.142 2380 3 6s
