#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

echo "Deploying squid to '$1'."
lxc exec $1 -- mkdir -p /apps/squid

lxc file push squid.yml $1/apps/squid/squid.yml
lxc file push squid.conf $1/apps/squid/squid.conf

lxc exec $1 -- docker stack deploy -c /apps/squid/squid.yml squid
