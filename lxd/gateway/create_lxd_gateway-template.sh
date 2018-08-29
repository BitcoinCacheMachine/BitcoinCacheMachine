#!/bin/bash

# WARNING, this script ASSUMES that the LXD daemon is either 1) running on the same host
# from which the script is being run (i.e., localhost). You can also provision `cachestack`
# to a remote LXD daemon by setting your local LXC client to use the specified remote LXD service
# You can use 'lxc remote add hostname hostname:8443 --accept-certificates to add a remote LXD'
# endpoint to your client.

# exit script if there's an error anywhere
set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# get the current directory where this script is so we can reference it later.
SCRIPT_DIR=$(pwd)

## Create the manager1 host from the lxd image template.
# bcm-template needs outbound internet (profile default) & privileged profile.
lxc init bcm-template gateway-template -p default -p docker_privileged -s bcm_data


lxc start gateway-template

sleep 10
lxc exec gateway-template -- apt-get install -y ufw

lxc exec gateway-template -- mkdir -p /etc/ufw

lxc file push ufw_before.rules gateway-template/etc/ufw/before.rules
lxc file push ufw_sysctl.conf gateway-template/etc/ufw/sysctl.conf

lxc exec gateway-template -- mkdir -p /etc/default
lxc file push ufw.conf gateway-template/etc/default/ufw

# disable systemd-resolved so we can run a DNS server locally.
# lxc file push resolved.conf bcm-gateway/etc/systemd/resolved.conf
# lxc exec gateway-template -- chown root:root /etc/systemd/resolved.conf
# lxc exec gateway-template -- chmod 0644 /etc/systemd/resolved.conf

lxc exec gateway-template -- chown root:root /etc/ufw/before.rules
lxc exec gateway-template -- chmod 0640 /etc/ufw/before.rules

lxc exec gateway-template -- chown root:root /etc/ufw/sysctl.conf
lxc exec gateway-template -- chmod 0644 /etc/ufw/sysctl.conf

lxc exec gateway-template -- chown root:root /etc/default/ufw
lxc exec gateway-template -- chmod 0644 /etc/default/ufw

lxc stop gateway-template

sleep 10

if [[ $(lxc info gateway-template | grep "Status: Stopped") ]]; then
    # so we can restore to a good known state.
    echo "Creating a snapshot from lxc host 'gateway-template'."
    lxc snapshot "gateway-template" gatewaySnapshot
fi