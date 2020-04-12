#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

if [[ -z $BCM_BOOTSTRAP_DIR ]]; then
    echo "ERROR: BCM_BOOTSTRAP_DIR IS not defined. Please set your environment."
    exit
fi

if [[ -z $BCM_VM_NAME ]]; then
    echo "ERROR: BCM_VM_NAME IS not defined. Please set your environment ~/.bashrc."
    exit
fi

# lxc profile device set bcmmacvlan eth0 nictype=macvlan parent="eno1"

# let's make sure we have an ssh keypair for the new vm
if [ ! -f "$HOME/.ssh/$BCM_VM_NAME.local" ]; then
    ssh-keygen -f "$HOME/.ssh/$BCM_VM_NAME.local" -t ecdsa -b 521
fi

# generate the custom cloud-init file. Cloud init installs and configures sshd
SSH_AUTHORIZED_KEY=$(<"$HOME/.ssh/$BCM_VM_NAME.local.pub")
export SSH_AUTHORIZED_KEY="$SSH_AUTHORIZED_KEY"
export PHYSICAL_NETWORK_INTERFACE="eno1"
envsubst <./bcm_vm_lxc_profile.yml >"/tmp/cloud-init.yml"

# let's create a profile for the BCM TYPE-1 VMs. This is per VM.
VM_PROFILE_NAME="$BCM_VM_NAME-vm"
if ! lxc profile list --format csv | grep -q "$VM_PROFILE_NAME"; then
    lxc profile create "$VM_PROFILE_NAME"
    cat /tmp/cloud-init.yml | lxc profile edit "$VM_PROFILE_NAME"
fi

shred -uz /tmp/cloud-init.yml

if lxc list --format csv | grep -q "$BCM_VM_NAME"; then
    lxc delete "$BCM_VM_NAME" --force
fi

if ! lxc image list --format csv --columns l | grep -q "lxc-vm-base"; then
    lxc image copy images:ubuntu/focal/cloud local: --auto-update --alias bcm-vm-base --vm
fi

lxc init --vm \
--profile="$VM_PROFILE_NAME" \
--profile="bcm-ssd" \
--profile="bcm-hdd" \
--profile="bcm-sd" \
bcm-vm-base \
"$BCM_VM_NAME"

#lxc network attach bcmmacvlan "$BCM_VM_NAME" eth0
#lxc config device add "$BCM_VM_NAME" eth0 nic nictype=macvlan parent="eno1" name="eth0"
lxc config device add "$BCM_VM_NAME" config disk source=cloud-init:config
lxc start "$BCM_VM_NAME"

IP_V4_ADDRESS=
while [ 1 ]; do
    IP_V4_ADDRESS="$(lxc list $BCM_VM_NAME --format csv --columns=4 | grep "enp5s0" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')" || true
    if [ ! -z "$IP_V4_ADDRESS" ]; then
        break
    else
        sleep 1
    fi
done

wait-for-it -t 60 "$IP_V4_ADDRESS:22"
SSH_PUBKEY_PATH="$HOME/.ssh/$BCM_VM_NAME.local.pub"
FQSN="ubuntu@$IP_V4_ADDRESS"

rsync -rv "$BCM_GIT_DIR/" -e "ssh -i $SSH_PUBKEY_PATH -o 'StrictHostKeyChecking=accept-new'" "$FQSN:/home/ubuntu/bcm"
ssh -i "$SSH_PUBKEY_PATH" "$FQSN" sudo bash -c "/home/ubuntu/bcm/init_bcm.sh --sudo-user=ubuntu"
ssh -i "$SSH_PUBKEY_PATH" "$FQSN" sudo bash -c "/home/ubuntu/bcm/install.sh"
ssh -i "$SSH_PUBKEY_PATH" "$FQSN" -- bash '/home/ubuntu/bcm/bcm deploy'


# # let's get the onion address and add it as a bcm-onion site. This is a management plane admin interface.
# MGMT_PLANE_ONION_ADDRESS="$(multipass exec "$VM_NAME" -- sudo cat /var/lib/tor/ssh/hostname)"
# if [[ ! -z $MGMT_PLANE_ONION_ADDRESS ]]; then
#     touch "$ENDPOINT_DIR/mgmt-onion.env"
#     {
#         echo "#!/bin/bash"
#         echo "$MGMT_PLANE_ONION_ADDRESS"
#     } >> "$ENDPOINT_DIR/mgmt-onion.env"
# fi
