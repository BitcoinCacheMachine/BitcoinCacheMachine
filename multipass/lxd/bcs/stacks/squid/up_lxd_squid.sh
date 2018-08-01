#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

echo "Deploying docker registry_mirrors to the Cache Stack."
lxc exec cachestack -- mkdir -p /apps/squid
lxc file push ./squid.yml cachestack/apps/squid/squid.yml
lxc exec cachestack -- docker stack deploy -c /apps/squid/squid.yml squid
