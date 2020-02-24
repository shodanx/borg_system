#!/bin/bash

export ANSIBLE_HOST_KEY_CHECKING=False

cd /etc/borg/deploy

ansible-playbook playbooks/backup.yml -i inventory

