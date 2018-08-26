#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

lxc exec underlay -- mkdir -p /apps/squid
lxc file push Dockerfile underlay/apps/squid/Dockerfile
lxc file push entrypoint.sh underlay/apps/squid/entrypoint.sh
lxc exec underlay -- docker build -t bcm-squid:latest /apps/squid
