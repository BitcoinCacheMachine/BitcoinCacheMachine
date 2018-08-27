#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

lxc exec gateway -- mkdir -p /apps/squid
lxc file push Dockerfile gateway/apps/squid/Dockerfile
lxc file push entrypoint.sh gateway/apps/squid/entrypoint.sh
lxc exec gateway -- docker build -t bcm-squid:latest /apps/squid
