#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

echo "Deploying squid to the active LXD endpoint."
lxc exec underlay -- mkdir -p /apps/squid

bash -c $BCM_LOCAL_GIT_REPO/docker_images/common/bcm-squid/build_lxd_bcm-squid.sh

lxc file push squid.yml underlay/apps/squid/squid.yml
lxc file push squid.conf underlay/apps/squid/squid.conf

lxc exec underlay -- docker stack deploy -c /apps/squid/squid.yml squid
