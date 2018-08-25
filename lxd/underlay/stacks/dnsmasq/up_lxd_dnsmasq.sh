#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

lxc exec underlay -- mkdir -p /apps/dnsmasq

lxc file push dnsmasq.yml underlay/apps/dnsmasq/dnsmasq.yml
lxc file push dnsmasq.conf underlay/apps/dnsmasq/dnsmasq.conf
lxc file push torrc underlay/apps/dnsmasq/torrc

lxc exec underlay -- docker stack deploy -c /apps/dnsmasq/dnsmasq.yml dnsmasq