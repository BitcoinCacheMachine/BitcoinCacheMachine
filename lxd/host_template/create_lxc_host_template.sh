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

    lxc init bcm-bionic-base -p bcm_default -p docker_privileged -n bcmbr0 $BCM_HOSTTEMPLATE_NAME

    lxc start $BCM_HOSTTEMPLATE_NAME
else
    echo "LXC image 'bcm-bionic-base' was not found. Exiting."
    exit
fi

sleep 5

# TODO provide configuration item to route these requests over local TOR proxy
echo "Installing required software on dockertemplate."
lxc exec $BCM_HOSTTEMPLATE_NAME -- apt-get update

# docker.io is the only package that seems to work seamlessly with
# storage backends. Using BTRFS since docker recognizes underlying file system
lxc exec $BCM_HOSTTEMPLATE_NAME -- apt-get install docker.io wait-for-it -qq

# lxc file push ./get-docker.sh $BCM_HOSTTEMPLATE_NAME/root/get-docker.sh
# lxc exec $BCM_HOSTTEMPLATE_NAME -- chmod +x /root/get-docker.sh
# lxc exec $BCM_HOSTTEMPLATE_NAME -- bash -c /root/get-docker.sh

if [[ $BCM_DEBUG = 1 ]]; then
    lxc exec $BCM_HOSTTEMPLATE_NAME -- apt-get install jq nmap curl ifmetric slurm tcptrack dnsutils tcpdump -qq
fi


## checking if this alleviates docker swarm troubles in lxc.
#https://github.com/stgraber/lxd/commit/255b875c37c87572a09e864b4fe6dd05a78b4d01
lxc exec $BCM_HOSTTEMPLATE_NAME -- touch /.dockerenv
lxc exec $BCM_HOSTTEMPLATE_NAME -- mkdir -p /etc/docker

# this helps suppress some warning messages.  TODO
lxc file push ./sysctl.conf $BCM_HOSTTEMPLATE_NAME/etc/sysctl.conf
lxc exec $BCM_HOSTTEMPLATE_NAME -- chmod 0644 /etc/sysctl.conf

# clean up the image before publication
lxc exec $BCM_HOSTTEMPLATE_NAME -- apt-get autoremove -qq
lxc exec $BCM_HOSTTEMPLATE_NAME -- apt-get clean -qq
lxc exec $BCM_HOSTTEMPLATE_NAME -- rm -rf /tmp/*

lxc exec $BCM_HOSTTEMPLATE_NAME -- systemctl stop docker
lxc exec $BCM_HOSTTEMPLATE_NAME -- systemctl enable docker

#stop the template since we don't need it running anymore.
lxc stop $BCM_HOSTTEMPLATE_NAME
lxc profile remove $BCM_HOSTTEMPLATE_NAME docker_privileged
lxc network detach bcmbr0 $BCM_HOSTTEMPLATE_NAME

# echo "Creating a snapshot of the lxd host 'dockertemplate' called 'bcmHostSnapshot'."
lxc snapshot $BCM_HOSTTEMPLATE_NAME bcmHostSnapshot

# if instructed, serve the newly created snapshot to trusted LXD hosts.
if [[ $(lxc list | grep "$BCM_HOSTTEMPLATE_NAME") ]]; then
    if [[ $BCM_ADMIN_IMAGE_BCMTEMPLATE_MAKE_PUBLIC = 1 ]]; then
        # if the template doesn't exist, publish it so remote clients can reach it.
        echo "Publishing $BCM_HOSTTEMPLATE_NAME/bcmHostSnapshot as a public lxd image 'bcm-template' on cluster '$(lxc remote get-default)'."
        lxc publish $BCM_HOSTTEMPLATE_NAME/bcmHostSnapshot --alias bcm-template
        #--public
    else
        echo "Publishing $BCM_HOSTTEMPLATE_NAME/bcmHostSnapshot as non-public lxd image cluster '$(lxc remote get-default)'."
        lxc publish $BCM_HOSTTEMPLATE_NAME/bcmHostSnapshot --alias bcm-template
    fi
fi