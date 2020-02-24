#!/bin/bash

export ANSIBLE_HOST_KEY_CHECKING=False

ansible-playbook playbooks/backup.yml -i inventory

