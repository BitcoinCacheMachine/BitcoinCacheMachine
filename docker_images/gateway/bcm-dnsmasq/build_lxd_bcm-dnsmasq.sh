#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

echo "Building 'bcm-dnsmasq:latest' docker image on LXC host '$1'."

# build the image for dnsmasq on$1
lxc exec $1 -- mkdir -p /apps/dnsmasq
lxc file push Dockerfile $1/apps/dnsmasq/Dockerfile
lxc file push dnsmasq.conf $1/apps/dnsmasq/dnsmasq.conf
lxc file push torrc $1/apps/dnsmasq/torrc
lxc file push entrypoint.sh $1/apps/dnsmasq/entrypoint.sh
lxc exec $1 -- docker build -t bcm-dnsmasq:latest /apps/dnsmasq
