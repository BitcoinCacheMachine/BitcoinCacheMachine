#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

echo "Building 'bcm-dnsmasq:latest' docker image on LXC host '$DOCKER_BUILD_LXC_COTAINER'. Consider using a BCM's Docker Registry."

# build the image for dnsmasq on$DOCKER_BUILD_LXC_COTAINER
lxc exec $DOCKER_BUILD_LXC_COTAINER -- mkdir -p /apps/dnsmasq
lxc file push Dockerfile $DOCKER_BUILD_LXC_COTAINER/apps/dnsmasq/Dockerfile
lxc file push dnsmasq.conf $DOCKER_BUILD_LXC_COTAINER/apps/dnsmasq/dnsmasq.conf
lxc file push torrc $DOCKER_BUILD_LXC_COTAINER/apps/dnsmasq/torrc
lxc file push entrypoint.sh $DOCKER_BUILD_LXC_COTAINER/apps/dnsmasq/entrypoint.sh
lxc exec $DOCKER_BUILD_LXC_COTAINER -- docker build -t bcm-dnsmasq:latest /apps/dnsmasq
