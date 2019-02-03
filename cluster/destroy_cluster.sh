#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=1090
source "$BCM_GIT_DIR/env"

# delete profile 'docker-privileged'
bash -c "$BCM_LXD_OPS/delete_lxc_profile.sh --profile-name=bcm_default"

if lxc storage list | grep -q "bcm_btrfs"; then
    lxc storage delete bcm_btrfs
fi

sudo lxd init --auto