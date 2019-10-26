#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

VM_NAME=

# TODO make interactive.

# DISK size is in GBs
DISK_SIZE="300"

# MEM_SIZE is in MB. 4092 = 4GB
MEM_SIZE="8096M"

# CPU_COUNT is cores.
CPU_COUNT=4
ENDPOINT_DIR=

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
        --endpoint-dir=*)
            ENDPOINT_DIR="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $VM_NAME ]]; then
    echo "Error: You MUST specify the VM name."
    exit
fi

if [[ -f "$ENDPOINT_DIR/id_rsa" ]]; then
    SSH_KEY_PATH="$ENDPOINT_DIR/id_rsa"
else
    echo "Error: '$ENDPOINT_DIR/id_rsa' does not exist!"
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

# generate the custom cloud-init file.
SSH_AUTHORIZED_KEY=$(<"$SSH_KEY_PATH.pub")
export SSH_AUTHORIZED_KEY="$SSH_AUTHORIZED_KEY"
envsubst <./cloud_init_template.yml >"$BCM_TMP_DIR/cloud-init.yml"

# launch the new VM with the custom cloud-init.
multipass launch --disk="$DISK_SIZE""GB" --mem="$MEM_SIZE" --cpus="$CPU_COUNT" --name="$VM_NAME" --cloud-init "$BCM_TMP_DIR/cloud-init.yml" bionic
rm "$BCM_TMP_DIR/cloud-init.yml"

multipass copy-files ./server_prep.sh "$VM_NAME:/home/multipass/server_prep.sh"

multipass exec "$VM_NAME"  -- chmod 0755 /home/multipass/server_prep.sh
multipass exec "$VM_NAME"  -- bash -c /home/multipass/server_prep.sh

# let's get the onion address and add it as a bcm-onion site. This is a management plane admin interface.
MGMT_PLANE_ONION_ADDRESS="$(multipass exec "$VM_NAME" -- sudo cat /var/lib/tor/ssh/hostname)"
if [[ ! -z $MGMT_PLANE_ONION_ADDRESS ]]; then
    touch "$ENDPOINT_DIR/mgmt-onion.env"
    {
        echo "#!/bin/bash"
        echo "$MGMT_PLANE_ONION_ADDRESS"
    } >> "$ENDPOINT_DIR/mgmt-onion.env"
fi

multipass restart "$VM_NAME"

IPV4_ADDRESS=$(multipass list --format csv | grep $VM_NAME | awk -F "\"*,\"*" '{print $3}')
if [[ ! -z $IPV4_ADDRESS && ! -z $VM_NAME ]]; then
    echo "$IPV4_ADDRESS    $VM_NAME" | sudo tee -a /etc/hosts
fi

# let's do an ssh-keyscan so we can get the remote identity added to our BCM_KNOWN_HOSTS_FILE file
ssh-keyscan -H "$VM_NAME" >> "$BCM_KNOWN_HOSTS_FILE"

rm -rf "$ENDPOINT_DIR/cloud-init.yml"
