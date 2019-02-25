#!/bin/bash

set -Eeu

if lxc image list --format csv | grep -q "$LXC_BCM_BASE_IMAGE_NAME"; then
    lxc image delete "$LXC_BCM_BASE_IMAGE_NAME"
fi

if lxc profile list | grep -q "bcm_default"; then
    lxc profile delete bcm_default
fi

if lxc storage list | grep -q "bcm_btrfs"; then
    lxc storage delete bcm_btrfs
fi
