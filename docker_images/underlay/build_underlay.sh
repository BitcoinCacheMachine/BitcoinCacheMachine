#!/bin/bash
# This scripts builds all images for 'underlay'

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

bash -c ../build_lxd_bcm-base.sh

bash -c ../common/bcm-tor/build_lxd_bcm-tor.sh

bash -c ./bcm-dnsmasq/build_lxd_bcm-dnsmasq.sh

