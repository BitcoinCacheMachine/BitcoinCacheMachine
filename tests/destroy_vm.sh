#!/bin/bash

set -Eeuo pipefail

if [[ -z $BCM_VM_NAME ]]; then
    echo "ERROR: BCM_VM_NAME IS not defined. Please set your environment ~/.bashrc."
    exit
fi

if lxc list | grep -q "$BCM_VM_NAME"; then
    lxc stop "$BCM_VM_NAME"
    lxc delete "$BCM_VM_NAME"
else
    echo "INFO: the lxc vm '$BCM_VM_NAME' was not found."
fi


lxc profile delete "$BCM_VM_NAME-vm"

# FILE="$HOME/.ssh/$BCM_VM_NAME.local.pub"
# if [ -f "$FILE" ]; then
#     rm "$FILE"
# fi

# FILE="$HOME/.ssh/$BCM_VM_NAME.local"
# if [ -f "$FILE" ]; then
#     rm "$FILE"
# fi

ssh-keygen -R "$BCM_VM_NAME.local"
