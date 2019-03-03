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
BCM_SSH_KEY_PATH=

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
        --ssh-key-path=*)
            BCM_SSH_KEY_PATH="${i#*=}"
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
echo "BCM_SSH_KEY_PATH: $BCM_SSH_KEY_PATH"

# we need to update the cloud-init to include the bcm user and it's associated SSH key.
# we'll create a temporary one here. It'll get purged AFTER the `bcm cluster create` process
# when the Trezor SSH keys are placed up there.

# generate the custom cloud-init file.
SSH_AUTHORIZED_KEY=$(<"$BCM_SSH_KEY_PATH.pub")
export SSH_AUTHORIZED_KEY="$SSH_AUTHORIZED_KEY"
envsubst <./cloud_init_template.yml >"$BCM_WORKING_DIR/cloud-init_bcm_""$VM_NAME.yml"

# launch the new VM with the custom cloud-init.
multipass launch --disk="$DISK_SIZE""GB" --mem="$MEM_SIZE" --cpus="$CPU_COUNT" --name="$VM_NAME" --cloud-init "$BCM_WORKING_DIR/cloud-init_bcm_""$VM_NAME.yml" bionic

multipass copy-files ./server_prep.sh "$VM_NAME:/home/multipass/server_prep.sh"

multipass exec "$VM_NAME"  -- chmod 0755 /home/multipass/server_prep.sh

multipass exec "$VM_NAME"  -- bash -c /home/multipass/server_prep.sh

multipass restart "$VM_NAME"

# call the following scripts so do a static /etc/hosts mapping since multipass doesn't natively do DNS (or I need more research)
bash -c "$BCM_GIT_DIR/cli/shared/update_controller_etc_hosts.sh"

# let's do an ssh-keyscan so we can get the remote identity added to our BCM_KNOWN_HOSTS_FILE file
ssh-keyscan -H "$VM_NAME" >> "$BCM_KNOWN_HOSTS_FILE"

rm -rf "$BCM_WORKING_DIR/cloud-init_bcm_""$VM_NAME.yml"
