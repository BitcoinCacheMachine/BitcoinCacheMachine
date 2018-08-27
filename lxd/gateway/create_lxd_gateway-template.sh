#!/bin/bash

# WARNING, this script ASSUMES that the LXD daemon is either 1) running on the same host
# from which the script is being run (i.e., localhost). You can also provision `cachestack`
# to a remote LXD daemon by setting your local LXC client to use the specified remote LXD service
# You can use 'lxc remote add hostname hostname:8443 --accept-certificates to add a remote LXD'
# endpoint to your client.

# exit script if there's an error anywhere
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# get the current directory where this script is so we can reference it later.
SCRIPT_DIR=$(pwd)

# create the lxdbrGateway network if it doesn't exist.
if [[ -z $(lxc network list | grep lxdbrGateway) ]]; then
    # a bridged network network for mgmt and outbound NAT by hosts.
    lxc network create lxdbrGateway ipv4.nat=true
else
    echo "lxdbrGateway already exists."
fi

# create the gatewayprofile profile if it doesn't exist.
if [[ -z $(lxc profile list | grep gatewayprofile) ]]; then
    lxc profile create gatewayprofile
fi

echo "Applying gateway_lxd_profile.yml to lxd profile 'gatewayprofile'."
cat gateway_lxd_profile.yml | lxc profile edit gatewayprofile

## Create the manager1 host from the lxd image template.
lxc init bcm-template gateway-template -p docker_priv -p gatewayprofile -s bcm_data

lxc profile apply gateway-template default,docker_priv

if [[ $BCM_GATEWAY_ENABLE_IP_FORWARDING = "true" ]]; then
    lxc start gateway-template

    sleep 10
    # let's start gateway so we can update some file permissions.
    # ufw firewall policy rules
    lxc file push ufw_before.rules gateway-template/etc/ufw/before.rules
    lxc file push ufw_sysctl.conf gateway-template/etc/ufw/sysctl.conf
    lxc file push ufw.conf gateway-template/etc/default/ufw

    # disable systemd-resolved so we can run a DNS server locally.
    lxc file push resolved.conf gateway-template/etc/systemd/resolved.conf

    lxc exec gateway-template -- chown root:root /etc/systemd/resolved.conf
    lxc exec gateway-template -- chmod 0644 /etc/systemd/resolved.conf

    lxc exec gateway-template -- chown root:root /etc/ufw/before.rules
    lxc exec gateway-template -- chmod 0640 /etc/ufw/before.rules

    lxc exec gateway-template -- chown root:root /etc/ufw/sysctl.conf
    lxc exec gateway-template -- chmod 0644 /etc/ufw/sysctl.conf

    lxc exec gateway-template -- chown root:root /etc/default/ufw
    lxc exec gateway-template -- chmod 0644 /etc/default/ufw

    lxc exec gateway-template -- ufw enable
    
    lxc stop gateway-template

    # I've seen where the snapshot doesn't always work right after the previous command.
    sleep 2
fi

# so we can restore to a good known state.
lxc snapshot gateway-template gatewaySnapshot
