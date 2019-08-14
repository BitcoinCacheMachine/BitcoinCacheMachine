#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

CONTINUE=0
CHOICE=n

if [[ $BCM_RUNTIME_DIR == "$HOME" ]]; then
    echo "WARNING: BCM reset will NOT run when 'runtime-dir=$HOME'"
    exit
fi

while [[ "$CONTINUE" == 0 ]]
do
    echo "WARNING: 'bcm reset' will delete the contents of '$BCM_RUNTIME_DIR' and will remove multipass, LXD, and docker from your localhost."
    read -rp "Are you sure you want to continue? (y/n):  "   CHOICE
    
    if [[ "$CHOICE" == "y" ]]; then
        rm -rf "$BCM_RUNTIME_DIR"
        CONTINUE=1
        elif [[ "$CHOICE" == "n" ]]; then
        exit
    else
        echo "Invalid entry. Please try again."
    fi
done

echo "Removing all BCM-related entries from /etc/hosts"
sudo sed -i "/bcm-/d" /etc/hosts

if [ -x "$(command -v multipass)" ]; then
    sudo snap remove multipass
else
    echo "Info: multipass was not installed."
fi

if [ -x "$(command -v lxc)" ]; then
    sudo lxd shutdown
    
    sudo snap remove lxd
else
    echo "Info: lxd was not installed."
fi

if [ -x "$(command -v docker)" ]; then
    sudo snap remove docker
else
    echo "Info: docker was not installed."
fi