#!/bin/bash

export ANSIBLE_HOST_KEY_CHECKING=False

cd /etc/borg/deploy

SERVER_NAME=`hostname -A`
RSA=`ssh-keyscan -t rsa $SERVER_NAME | awk '{print $3}'`

mkdir -p roles/add_borg_system/vars/

echo "---"                            > roles/add_borg_system/vars/main.yml
echo "borg_server_name: $SERVER_NAME">> roles/add_borg_system/vars/main.yml
echo "borg_server_pubrsakey: $RSA"   >> roles/add_borg_system/vars/main.yml


ansible-playbook playbooks/backup.yml -i inventory

