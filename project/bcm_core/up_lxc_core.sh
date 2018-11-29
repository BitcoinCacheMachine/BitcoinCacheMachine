#!/usr/bin/env bash

set -Eeuox pipefail
cd "$(dirname "$0")" 

# This brings up 'bcm-gateway' and 'bcm-kafka' LXC hosts and populates
# the respective docker daemons.

bash -c ./host_template/up_lxc_host_template.sh

# All tiers require that the bcm-template image be available.
# let's look for it before we even attempt anything.
if lxc image list --format csv | grep -q "bcm-template"; then
    bash -c ./tiers/up_bcm_core_tiers.sh
else
    echo "LXC image 'bcm-template' doesn't exist. Can't deploy BCM tiers."
fi