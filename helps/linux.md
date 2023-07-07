# Helps Linux

## Print permissions in octal

stat -c '%A %a %n' .ssh/id_ecdsa

## Generate ssh key pair

ssh-keygen -q -t ecdsa -b 521 -N '' -f ~/.ssh/rancher-key-ecdsa <<<y >/dev/null 2>&1

## Copy public key for remote server

sshpass -p 'vagrant' ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/rancher-key-ecdsa root@debian-server02

## Connect in remote

ssh -o StrictHostKeyChecking=no -i ~/.ssh/rancher-key-ecdsa  root@control-plane02