#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

if [[ -z "$BCM_VM_NAME" ]]; then
    echo "ERROR: BCM_VM_NAME IS not defined. Please set your environment ~/.bashrc."
    exit
fi

if lxc list --format csv | grep -q "$BCM_VM_NAME"; then
    lxc delete "$BCM_VM_NAME" --force
fi

# remove the host from your SSH known_hosts list
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$BCM_VM_NAME.local"

FILE="$SSHHOME/$BCM_VM_NAME.local.pub"
if [ -f "$FILE" ]; then
    rm "$FILE"
fi

FILE="$SSHHOME/$BCM_VM_NAME.local"
if [ -f "$FILE" ]; then
    rm "$FILE"
fi
