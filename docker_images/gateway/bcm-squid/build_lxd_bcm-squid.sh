#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

lxc exec $1 -- mkdir -p /apps/squid
lxc file push Dockerfile $1/apps/squid/Dockerfile
lxc file push entrypoint.sh $1/apps/squid/entrypoint.sh
lxc exec $1 -- docker build -t bcm-squid:latest /apps/squid
