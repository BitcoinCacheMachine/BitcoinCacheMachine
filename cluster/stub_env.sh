#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_ENDPOINT_NAME=
IS_MASTER=0

for i in "$@"; do
    case $i in
        --endpoint-name=*)
            BCM_ENDPOINT_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --master)
            IS_MASTER=1
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

ENDPOINT_DIR="$TEMP_DIR/$BCM_ENDPOINT_NAME"
mkdir -p "$ENDPOINT_DIR"
touch "$ENV_FILE"

# generate an LXD secret for the new VM lxd endpoint.
export BCM_ENDPOINT_NAME=$BCM_ENDPOINT_NAME

# first let's check on the remote SSH service.
wait-for-it -t 60 "$BCM_SSH_HOSTNAME:22"

SSH_KEY_FILE="$ENDPOINT_DIR/id_rsa"

# this key is for temporary use and used only during initial provisioning.
ssh-keygen -t rsa -b 4096 -C "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" -f "$SSH_KEY_FILE" -N ""
chmod 400 "$SSH_KEY_FILE.pub"

if [[ $BCM_SSH_HOSTNAME == *.onion ]]; then
    torify ssh-copy-id -i "$SSH_KEY_FILE" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME"
else
    ssh-copy-id -i "$SSH_KEY_FILE" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME"
fi

# generate Trezor-backed SSH keys for interactively login.
SSH_IDENTITY="$BCM_SSH_USERNAME"'@'"$BCM_SSH_HOSTNAME"
bcm ssh newkey --username="$BCM_SSH_USERNAME" --hostname="$BCM_SSH_HOSTNAME" --push

if [[ $BCM_SSH_HOSTNAME == *.onion ]]; then
    torify ssh -i "$SSH_KEY_FILE" -t "$SSH_IDENTITY" ip link show
else
    ssh -i "$SSH_KEY_FILE" -t "$SSH_IDENTITY" ip link show
fi
# TODO Do some error checking on network interface selection.
read -rp "Enter the name of the physical network interface you want to use for the management:  " BCM_LXD_PHYSICAL_INTERFACE

export BCM_LXD_PHYSICAL_INTERFACE="$BCM_LXD_PHYSICAL_INTERFACE"
BCM_LXD_SECRET="$(apg -n 1 -m 30 -M CN)"
export BCM_LXD_SECRET="$BCM_LXD_SECRET"
if [ $IS_MASTER -eq 1 ]; then
    envsubst <./env/master_defaults.env >$ENV_FILE
    elif [ $IS_MASTER -ne 1 ]; then
    envsubst <./env/member_defaults.env >$ENV_FILE
else
    echo "Incorrect usage. Please specify whether $BCM_ENDPOINT_NAME is an LXD cluster master or member."
fi

if [ $IS_MASTER -eq 1 ]; then
    envsubst <./lxd_preseed/lxd_master_preseed.yml >"$TEMP_DIR/$BCM_ENDPOINT_NAME/lxd_preseed.yml"
    elif [ $IS_MASTER -ne 1 ]; then
    envsubst <./lxd_preseed/lxd_member_preseed.yml >"$TEMP_DIR/$BCM_ENDPOINT_NAME/lxd_preseed.yml"
else
    echo "Incorrect usage. Please specify whether $BCM_ENDPOINT_NAME is an LXD cluster master or member."
fi