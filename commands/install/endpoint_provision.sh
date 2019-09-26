#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

YAML_TEXT=

for i in "$@"; do
    case $i in
        --yaml-text=*)
            YAML_TEXT="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

sudo apt-get update -y
sudo apt-get remove lxd lxd-client -y
sudo apt-get autoremove -y
sudo apt-get install tor wait-for-it apg -y

echo "$YAML_TEXT" | sudo lxd init --preseed

# all LXC operations use the local unix socket; BCM DOES NOT
# employ HTTPS -based LXD. All management plane operations are
# via SSH.
lxc remote set-default "local"

# commands in ~/.bashrc are delimited by these literals.
BASHRC_FILE="$HOME/.bashrc"
if [[ ! -f $BASHRC_FILE ]]; then
    touch "$BASHRC_FILE"
    sudo chmod 0644 "$BASHRC_FILE"
fi

BASHRC_TEXT="export PATH=$""PATH:$HOME/.bcmcode"
source "$BASHRC_FILE"
if ! grep -qF "$BASHRC_TEXT" "$BASHRC_FILE"; then
    echo "$BASHRC_TEXT" | tee -a "$BASHRC_FILE"
fi
