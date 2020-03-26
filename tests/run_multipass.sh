#!/bin/bash

set -Eeou pipefail

BCM_GIT_DIR=$(pwd)

if [[ -z $BCM_BOOTSTRAP_DIR ]]; then
    echo "ERROR: BCM_BOOTSTRAP_DIR IS not defined. Please set your environment."
    exit
fi

if [[ -z $BCM_VM_NAME ]]; then
    echo "ERROR: BCM_VM_NAME IS not defined. Please set your environment ~/.bashrc."
    exit
fi

# install multipass; all bcm back-end instances exist as multipass vms.
if [[ ! -f "$(command -v multipass)" ]]; then
    sudo snap install --edge --classic multipass
fi

if ! multipass list | grep -q bcm; then
    multipass launch --disk="50GB" --mem="4098MB" --cpus="4" --name="$BCM_VM_NAME" daily:20.04
    #daily:lts
fi

multipass exec "$BCM_VM_NAME" -- apt-get update && apt-get install -y sshfs

multipass exec "$BCM_VM_NAME" -- mkdir -p /usr/local/bin
multipass exec "$BCM_VM_NAME" -- mkdir -p /home/ubuntu/.bcmbootstrap

multipass mount "$BCM_GIT_DIR"/../ "$BCM_VM_NAME:/usr/local/bin"
multipass mount "$BCM_BOOTSTRAP_DIR"/../ "$BCM_VM_NAME:/home/ubuntu/.bcmbootstrap"

# since we are mounting the BCM_GIT_DIR using multipass, we will do a tor-only bcm_init
multipass exec "$BCM_VM_NAME" -- sudo bash -c /usr/local/bin/init_bcm.sh --tor-only

# run the install script.
multipass exec "$BCM_VM_NAME" -- sudo bash -c /usr/local/bin/install_local.sh

multipass exec "$BCM_VM_NAME" -- bcm deploy
