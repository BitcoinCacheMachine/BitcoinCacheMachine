#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# build the image for dnsmasq
lxc exec underlay -- mkdir -p /apps/dnsmasq
lxc file push Dockerfile underlay/apps/dnsmasq/Dockerfile
lxc file push dnsmasq.conf underlay/apps/dnsmasq/dnsmasq.conf
lxc file push torrc underlay/apps/dnsmasq/torrc
lxc file push entrypoint.sh underlay/apps/dnsmasq/entrypoint.sh
lxc exec underlay -- docker build -t bcm-dnsmasq:latest /apps/dnsmasq
