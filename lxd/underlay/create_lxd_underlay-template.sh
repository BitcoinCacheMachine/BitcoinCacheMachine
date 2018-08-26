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

# create the lxdbrUnderlay network if it doesn't exist.
if [[ -z $(lxc network list | grep lxdbrUnderlay) ]]; then
    # a bridged network network for mgmt and outbound NAT by hosts.
    lxc network create lxdbrUnderlay ipv4.nat=true
else
    echo "lxdbrUnderlay already exists."
fi

# create the underlayprofile profile if it doesn't exist.
if [[ -z $(lxc profile list | grep underlayprofile) ]]; then
    lxc profile create underlayprofile
fi

echo "Applying ./underlay_lxd_profile.yml to lxd profile 'underlayprofile'."
cat ./underlay_lxd_profile.yml | lxc profile edit underlayprofile

# create the underlay container if it doesn't exist
if [[ -z $(lxc list | grep underlay-template) ]]; then
    #lxc init ubuntu:18.04 -p default -p underlayprofile -s bcm_data underlay
    if [[ $BCM_LXD_EXTERNAL_BCTEMPLATE_REMOTE = "none" ]] ; then
        #lxc init bctemplate underlay -p default -p docker_priv -p underlayprofile -s bcm_data
        lxc copy dockertemplate/bcmHostSnapshot underlay-template
    else
        lxc init $BCM_LXD_EXTERNAL_BCTEMPLATE_REMOTE:bctemplate underlay-template
    fi
else
  echo "LXC container 'underlay-template' already exists."
fi

lxc profile apply underlay-template default,docker_priv

if [[ $BCM_UNDERLAY_ENABLE_IP_FORWARDING = "true" ]]; then
    # let's start underlay so we can update some file permissions.
    # ufw firewall policy rules
    lxc file push ufw_before.rules underlay-template/etc/ufw/before.rules
    lxc file push ufw_sysctl.conf underlay-template/etc/ufw/sysctl.conf
    lxc file push ufw.conf underlay-template/etc/default/ufw

    # disable systemd-resolved so we can run a DNS server locally.
    lxc file push resolved.conf underlay-template/etc/systemd/resolved.conf

    lxc start underlay-template

    lxc exec underlay-template -- chown root:root /etc/systemd/resolved.conf
    lxc exec underlay-template -- chmod 0644 /etc/systemd/resolved.conf

    lxc exec underlay-template -- chown root:root /etc/ufw/before.rules
    lxc exec underlay-template -- chmod 0640 /etc/ufw/before.rules

    lxc exec underlay-template -- chown root:root /etc/ufw/sysctl.conf
    lxc exec underlay-template -- chmod 0644 /etc/ufw/sysctl.conf

    lxc exec underlay-template -- chown root:root /etc/default/ufw
    lxc exec underlay-template -- chmod 0644 /etc/default/ufw

    lxc exec underlay-template -- ufw enable

fi

lxc stop underlay-template

# so we can restore to a good known state.
lxc snapshot underlay-template underlaySnapshot
