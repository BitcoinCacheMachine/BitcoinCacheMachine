#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"


# build the image for dnsmasq on$BCM_LXC_GATEWAY_CONTAINER_NAME
lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- mkdir -p /apps/dnsmasq

echo "Building 'bcm-dnsmasq:latest' docker image on LXC host '$BCM_LXC_GATEWAY_CONTAINER_NAME'."
lxc file push Dockerfile $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/dnsmasq/Dockerfile
lxc file push entrypoint.sh $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/dnsmasq/entrypoint.sh
lxc file push dnsmasq.conf $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/dnsmasq/dnsmasq.conf

lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker build -t bcm-dnsmasq:latest /apps/dnsmasq
