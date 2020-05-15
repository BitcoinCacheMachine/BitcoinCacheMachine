#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

if [[ -z "$BCM_VM_NAME" ]]; then
    echo "ERROR: BCM_VM_NAME IS not defined. Please set your environment ~/.bashrc."
    exit
fi

# let's make sure we have an ssh keypair for the new vm
if [ ! -f "$SSHHOME/$BCM_VM_NAME.local" ]; then
    ssh-keygen -f "$SSHHOME/$BCM_VM_NAME.local" -t ecdsa -b 521 -N "$(pass bcm/$BCM_VM_NAME)"
fi

# generate the custom cloud-init file. Cloud init installs and configures sshd
SSH_AUTHORIZED_KEY=$(<"$SSHHOME/$BCM_VM_NAME.local.pub")
export SSH_AUTHORIZED_KEY="$SSH_AUTHORIZED_KEY"
envsubst <./bcm_vm_lxc_profile.yml >"/tmp/cloud-init.yml"

# let's create a profile for the BCM TYPE-1 VMs. This is per VM.
VM_PROFILE_NAME="$BCM_VM_NAME"
if ! lxc profile list --format csv | grep -q "$VM_PROFILE_NAME"; then
    lxc profile create "$VM_PROFILE_NAME"
fi

cat /tmp/cloud-init.yml | lxc profile edit "$VM_PROFILE_NAME"
shred -uz /tmp/cloud-init.yml

for LXC_IMAGE in bcm-vm-base bcm-lxc-base; do
    if ! lxc image list --format csv --columns l | grep -q "$LXC_IMAGE"; then
        # if we have the image locally in our disk cache, let's import it.
        if [ -f "$BCM_CACHE_DIR/$LXC_IMAGE" ]; then
            lxc image import "$BCM_CACHE_DIR/$LXC_IMAGE" "$BCM_CACHE_DIR/$LXC_IMAGE.root" --alias "$LXC_IMAGE"
        else
            # if the image doesn't exist, download it from Ubuntu's image server
            # TODO see if we can fetch this file from a more censorship-resistant source, e.g., ipfs
            if [[ "$LXC_IMAGE" == *"-vm-"* ]]; then
                lxc image copy images:ubuntu/focal/cloud local: --alias "$LXC_IMAGE" --vm --public
            else
                lxc image copy images:ubuntu/focal/cloud local: --alias "$LXC_IMAGE" --public
            fi
        fi
        
        # if the cache'd entry doesn't exist, let's cache it out to avoid subsequent network IO
        if [ ! -f "$BCM_CACHE_DIR/$LXC_IMAGE" ]; then
            lxc image export "$LXC_IMAGE" "$BCM_CACHE_DIR/$LXC_IMAGE"
        fi
    fi
done

lxc init --vm \
--profile="$VM_PROFILE_NAME" \
--profile="bcm-ssd" \
bcm-vm-base \
"$BCM_VM_NAME"

#--profile="bcm-hdd" \
# --profile="bcm-sd" \

#lxc network attach bcmmacvlan "$BCM_VM_NAME" eth0
lxc config device add "$BCM_VM_NAME" eth0 nic nictype=macvlan parent="$BCM_MACVLAN_INTERFACE" name="eth0"
lxc config device add "$BCM_VM_NAME" config disk source=cloud-init:config
lxc start "$BCM_VM_NAME"

IP_V4_ADDRESS=
while [ 1 ]; do
    IP_V4_ADDRESS="$(lxc list $BCM_VM_NAME --format csv --columns=4 | grep enp5s0 | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')" || true
    if [ -n "$IP_V4_ADDRESS" ]; then
        break
    else
        sleep 1
    fi
done

# TODO add snapshot to VM image so when we run 'bcm vm' we can start from a prepared image
# TODO maybe we can use the 'bcm vm --fresh' command to make it clear we want to start with a fresh non-snapshotted image

#lxc file push "$BCM_GIT_DIR" "$BCM_VM_NAME/home/ubuntu/bcm" -r -p

wait-for-it -t 120 "$IP_V4_ADDRESS:22"
SSH_PUBKEY_PATH="$SSHHOME/$BCM_VM_NAME.local"
FQSN="ubuntu@$IP_V4_ADDRESS"

rsync -rv "$BCM_GIT_DIR/" -e "ssh -i $SSH_PUBKEY_PATH -o 'StrictHostKeyChecking=accept-new'" "$FQSN:/home/ubuntu/bcm"
ssh -i "$SSH_PUBKEY_PATH" "$FQSN" bash -c "/home/ubuntu/bcm/install.sh"

# rsync -rv "$BCM_CACHE_DIR/lxc/" -e "ssh -i $SSH_PUBKEY_PATH -o 'StrictHostKeyChecking=accept-new'" "$FQSN:/home/ubuntu/.local/bcm/lxc"
# ssh -i "$SSH_PUBKEY_PATH" "$FQSN" -- bash '/home/ubuntu/bcm/bcm deploy'


# # let's get the onion address and add it as a bcm-onion site. This is a management plane admin interface.
# MGMT_PLANE_ONION_ADDRESS="$(multipass exec "$VM_NAME" -- sudo cat /var/bc`h/hostname)"
# if [[ -n $MGMT_PLANE_ONION_ADDRESS ]]; then
#     touch "$ENDPOINT_DIR/mgmt-onion.env"
#     {
#         echo "#!/bin/bash"
#         echo "$MGMT_PLANE_ONION_ADDRESS"
#     } >> "$ENDPOINT_DIR/mgmt-onion.env"
# fi
