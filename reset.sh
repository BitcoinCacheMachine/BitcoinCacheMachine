#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

source ./env

# let's remove everything bcm related;
BCM_VM_NAME="$BCM_VM_NAME" ./uninstall.sh --storage
# --lxd --cache
# --storage
# --cache
# --lxd

# we need to source our potentially new ~/.bashrc before calling ./install.
source "$HOME/.bashrc"

# install bcm
./install.sh

# We provision in Type-1 VMs if supported.
if lxc info | grep -q "virtual-machines"; then
    BCM_VM_NAME="$BCM_VM_NAME" bash -c ./commands/vm/up_vm.sh
fi
