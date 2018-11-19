#!/usr/bin/env bash

set -eu
cd "$(dirname "$0")"
source ./defaults.sh

if [[ ! -z $(lxc image list | grep bcm-template) ]]; then
    echo "The LXD image 'bcm-template' already exists. Exiting."
    exit
fi

echo "LXC image 'bcm-template' does not exist. Creating one."
# only execute if bcm_btrfs is non-zero
if [[ $(lxc image list | grep "bcm-bionic-base") ]]; then
    # initialize the lxc container to the active lxd endpoint.
    ./create_network.sh

    sleep 2

    lxc init bcm-bionic-base -p bcm_default -p docker_privileged -n bcmbr0 bcm-host-template

    lxc start bcm-host-template
else
    echo "LXC image 'bcm-bionic-base' was not found. Exiting."
    exit
fi

sleep 5

# TODO provide configuration item to route these requests over local TOR proxy
echo "Installing required software on dockertemplate."
lxc exec bcm-host-template -- apt-get update

# docker.io is the only package that seems to work seamlessly with
# storage backends. Using BTRFS since docker recognizes underlying file system
lxc exec bcm-host-template -- apt-get install docker.io wait-for-it -qq
lxc exec bcm-host-template -- apt-get install jq nmap curl ifmetric slurm tcptrack dnsutils tcpdump -qq



## checking if this alleviates docker swarm troubles in lxc.
#https://github.com/stgraber/lxd/commit/255b875c37c87572a09e864b4fe6dd05a78b4d01
lxc exec bcm-host-template -- touch /.dockerenv
lxc exec bcm-host-template -- mkdir -p /etc/docker

# this helps suppress some warning messages.  TODO
lxc file push ./sysctl.conf bcm-host-template/etc/sysctl.conf
lxc exec bcm-host-template -- chmod 0644 /etc/sysctl.conf

# clean up the image before publication
lxc exec bcm-host-template -- apt-get autoremove -qq
lxc exec bcm-host-template -- apt-get clean -qq
lxc exec bcm-host-template -- rm -rf /tmp/*

lxc exec bcm-host-template -- systemctl stop docker
lxc exec bcm-host-template -- systemctl enable docker

#stop the template since we don't need it running anymore.
lxc stop bcm-host-template
lxc profile remove bcm-host-template docker_privileged
lxc network detach bcmbr0 bcm-host-template

# echo "Creating a snapshot of the lxd host 'dockertemplate' called 'bcmHostSnapshot'."
lxc snapshot bcm-host-template bcmHostSnapshot

# if instructed, serve the newly created snapshot to trusted LXD hosts.
if [[ $(lxc list | grep "bcm-host-template") ]]; then
    echo "Publishing bcm-host-template/bcmHostSnapshot 'bcm-template' on cluster '$(lxc remote get-default)'."
    lxc publish bcm-host-template/bcmHostSnapshot --alias bcm-template
fi