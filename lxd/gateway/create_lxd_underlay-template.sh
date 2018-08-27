#!/bin/bash

# WARNING, this script ASSUMES that the LXD daemon is either 1) running on the same host
# from which the script is being run (i.e., localhost). You can also provision Cache Stack
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

echo "Applying ./gateway_lxd_profile.yml to lxd profile 'gatewayprofile'."
cat ./gateway_lxd_profile.yml | lxc profile edit gatewayprofile

# create the gateway container if it doesn't exist
if [[ -z $(lxc list | grep gateway-template) ]]; then
    #lxc init ubuntu:18.04 -p default -p gatewayprofile -s bcm_data gateway
    if [[ $BCM_LXD_EXTERNAL_BCTEMPLATE_REMOTE = "none" ]] ; then
        #lxc init bctemplate gateway -p default -p docker_priv -p gatewayprofile -s bcm_data
        lxc copy dockertemplate/bcmHostSnapshot gateway-template
    else
        lxc init $BCM_LXD_EXTERNAL_BCTEMPLATE_REMOTE:bctemplate gateway-template
    fi
else
  echo "LXC container 'gateway-template' already exists."
fi

lxc profile apply gateway-template default,docker_priv

if [[ $BCM_GATEWAY_ENABLE_IP_FORWARDING = "true" ]]; then
    # let's start gateway so we can update some file permissions.
    # ufw firewall policy rules
    lxc file push ufw_before.rules gateway-template/etc/ufw/before.rules
    lxc file push ufw_sysctl.conf gateway-template/etc/ufw/sysctl.conf
    lxc file push ufw.conf gateway-template/etc/default/ufw

    # disable systemd-resolved so we can run a DNS server locally.
    lxc file push resolved.conf gateway-template/etc/systemd/resolved.conf

    lxc start gateway-template

    lxc exec gateway-template -- chown root:root /etc/systemd/resolved.conf
    lxc exec gateway-template -- chmod 0644 /etc/systemd/resolved.conf

    lxc exec gateway-template -- chown root:root /etc/ufw/before.rules
    lxc exec gateway-template -- chmod 0640 /etc/ufw/before.rules

    lxc exec gateway-template -- chown root:root /etc/ufw/sysctl.conf
    lxc exec gateway-template -- chmod 0644 /etc/ufw/sysctl.conf

    lxc exec gateway-template -- chown root:root /etc/default/ufw
    lxc exec gateway-template -- chmod 0644 /etc/default/ufw

    lxc exec gateway-template -- ufw enable

fi

lxc stop gateway-template

# so we can restore to a good known state.
lxc snapshot gateway-template gateway
