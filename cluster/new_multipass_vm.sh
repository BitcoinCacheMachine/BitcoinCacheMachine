#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

VM_NAME=

# DISK size is in GBs
DISK_SIZE="50"

# MEM_SIZE is in MB. 4092 = 4GB
MEM_SIZE="4098"

# CPU_COUNT is cores.
CPU_COUNT=4

for i in "$@"; do
    case $i in
        --vm-name=*)
            VM_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --disk-size=*)
            DISK_SIZE="${i#*=}"
            shift # past argument=value
        ;;
        --mem-size=*)
            MEM_SIZE="${i#*=}"
            shift # past argument=value
        ;;
        --cups=*)
            CPU_COUNT="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $VM_NAME ]]; then
    echo "ERROR: You MUST specify the VM name."
    exit
fi

echo "Creating a new multipass VM with the following resources:"

echo "VM_NAME:  $VM_NAME"
echo "DISK_SIZE $DISK_SIZE"
echo "MEM_SIZE: $MEM_SIZE"
echo "CPU_COUNT: $CPU_COUNT"

# we need to update the cloud-init to include the bcm user and it's associated SSH key.
# we'll create a temporary one here. It'll get purged AFTER the `bcm cluster create` process
# when the Trezor SSH keys are placed up there.

# let's generate a temporary SSH key.

SSH_KEY_FILE="$BCM_TEMP_DIR/id_rsa_bcm_$VM_NAME"
if [[ ! -f $SSH_KEY_FILE ]]; then
    # this key is for temporary use and used only during initial provisioning.
    ssh-keygen -t rsa -b 4096 -C "bcm@$VM_NAME" -f "$SSH_KEY_FILE" -N ""
    chmod 400 "$SSH_KEY_FILE.pub"
fi

SSH_AUTHORIZED_KEY=$(<"$SSH_KEY_FILE.pub")

export SSH_AUTHORIZED_KEY="$SSH_AUTHORIZED_KEY"
envsubst <./cloud_init_template.yml >"$BCM_TEMP_DIR/cloud-init_bcm_""$VM_NAME.yml"

multipass launch --disk="$DISK_SIZE""GB" --mem="$MEM_SIZE" --cpus="$CPU_COUNT" --name="$VM_NAME" --cloud-init ./cloud_init_template.yml bionic

multipass restart "$VM_NAME"

IPV4_ADDRESS=$(multipass list --format csv | grep bcm-pegasus | awk -F "\"*,\"*" '{print $3}')

if grep -Fxq "$VM_NAME" /etc/hosts; then
    echo "REMOVING TEXT"
    sed -i "/$VM_NAME/d" /etc/hosts
fi

echo "$IPV4_ADDRESS   $VM_NAME" | sudo tee -a /etc/hosts

#rm -rf "$BCM_TEMP_DIR/cloud-init_bcm_""$VM_NAME.yml"