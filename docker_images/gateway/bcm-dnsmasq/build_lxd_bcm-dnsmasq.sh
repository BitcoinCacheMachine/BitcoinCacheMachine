#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# build the image for dnsmasq
lxc exec gateway -- mkdir -p /apps/dnsmasq
lxc file push Dockerfile gateway/apps/dnsmasq/Dockerfile
lxc file push dnsmasq.conf gateway/apps/dnsmasq/dnsmasq.conf
lxc file push torrc gateway/apps/dnsmasq/torrc
lxc file push entrypoint.sh gateway/apps/dnsmasq/entrypoint.sh
lxc exec gateway -- docker build -t bcm-dnsmasq:latest /apps/dnsmasq
