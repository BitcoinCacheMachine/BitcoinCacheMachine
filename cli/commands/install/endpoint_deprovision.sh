#!/bin/bash

set -Eeu

if lxc image list --format csv | grep -q "$LXC_BCM_BASE_IMAGE_NAME"; then
    lxc image delete "$LXC_BCM_BASE_IMAGE_NAME"
fi

if lxc profile list --format csv | grep "default" | grep -q ",0" ; then
    lxc profile delete default
fi

if lxc storage list | grep -q "bcm_btrfs"; then
    lxc storage delete bcm_btrfs
fi
