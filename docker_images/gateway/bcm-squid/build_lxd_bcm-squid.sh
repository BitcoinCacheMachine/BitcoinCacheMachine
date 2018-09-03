#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- mkdir -p /apps/squid
lxc file push Dockerfile $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/squid/Dockerfile
lxc file push entrypoint.sh $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/squid/entrypoint.sh
lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker build -t bcm-squid:latest /apps/squid
