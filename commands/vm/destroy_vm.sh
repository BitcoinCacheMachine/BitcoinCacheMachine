#!/bin/bash

set -Eeuox pipefail

if [[ -z "$BCM_VM_NAME" ]]; then
    echo "ERROR: BCM_VM_NAME IS not defined. Please set your environment ~/.bashrc."
    exit
fi

if lxc list --format csv | grep -q "$BCM_VM_NAME"; then
    lxc delete "$BCM_VM_NAME" --force
fi

if lxc profile list --format csv | grep -q "$BCM_VM_NAME-vm"; then
    lxc profile delete "$BCM_VM_NAME-vm"
fi

FILE="$HOME/.ssh/$BCM_VM_NAME.local.pub"
if [ -f "$FILE" ]; then
    rm "$FILE"
fi

FILE="$HOME/.ssh/$BCM_VM_NAME.local"
if [ -f "$FILE" ]; then
    rm "$FILE"
fi

ssh-keygen -R "$BCM_VM_NAME.local"
