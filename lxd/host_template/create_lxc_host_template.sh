#!/usr/bin/env bash

set -eu
cd "$(dirname "$0")"

if [[ ! -z $(lxc image list | grep bcm-template) ]]; then
    echo "The LXD image 'bcm-template' already exists. Exiting."
    exit
fi




echo "LXC image 'bcm-template' does not exist. Creating one."
# only execute if bcm_zfs is non-zero
if [[ $(lxc image list | grep "bcm-bionic-base") ]]; then
    # initialize the lxc container to the active lxd endpoint.
    
    #create and populate the required networks
    if [[ -z $(lxc network list | grep bcmbr0) ]]; then
        lxc network create bcmbr0
    fi

    lxc init bcm-bionic-base -p bcm_default -p docker_privileged -n bcmbr0 dockertemplate
    lxc start dockertemplate
fi

sleep 10

# TODO provide configuration item to route these requests over local TOR proxy
echo "Installing required software on dockertemplate."
#lxc exec dockertemplate -- apt-get install tor wait-for-it
#lxc file push ./torrc dockertemplate/etc/tor/torrc
#lxc exec dockertemplate -- service tor restart
#lxc exec dockertemplate -- wait-for-it -t 0 127.0.11.1:9050

# install docker - the script get-docker.sh does an apt-get update
lxc file push get-docker.sh dockertemplate/root/get-docker.sh
lxc exec dockertemplate -- bash -c "/root/get-docker.sh" >>/dev/null
lxc exec dockertemplate -- rm /root/get-docker.sh


if [[ $BCM_DEBUG = 1 ]]; then
    lxc exec dockertemplate -- apt-get install -y jq nmap curl ifmetric slurm tcptrack dnsutils tcpdump
fi

#p the current template dockerd instance since we're about to create a snapshot
#Enable the docker daemon to start by default.
lxc exec dockertemplate -- systemctl stop docker
lxc exec dockertemplate -- systemctl enable docker

## checking if this alleviates docker swarm troubles in lxc.
#https://github.com/stgraber/lxd/commit/255b875c37c87572a09e864b4fe6dd05a78b4d01
lxc exec dockertemplate -- touch /.dockerenv

lxc file push ./sysctl.conf dockertemplate/etc/sysctl.conf
lxc exec dockertemplate -- chmod 0644 /etc/sysctl.conf

lxc exec dockertemplate -- apt-get autoremove -y
lxc exec dockertemplate -- apt-get clean
lxc exec dockertemplate -- rm -rf /tmp/*

# stop the template since we don't need it running anymore.
lxc stop dockertemplate

lxc profile remove dockertemplate docker_privileged
lxc network detach bcmbr0 dockertemplate
#lxc network delete bcmbr0

echo "Creating a snapshot of the lxd host 'dockertemplate' called 'bcmHostSnapshot'."
lxc snapshot dockertemplate bcmHostSnapshot

# only do publish the 'bcm-template' if it doesn't exist already.
if [[ -z $(lxc image list -c l | grep "bcm-template") ]]; then
    # if instructed, serve the newly created snapshot to trusted LXD hosts.
    if [[ $(lxc list | grep dockertemplate) ]]; then
        if [[ $BCM_ADMIN_IMAGE_BCMTEMPLATE_MAKE_PUBLIC = "true" ]]; then
            # if the template doesn't exist, publish it so remote clients can reach it.
            echo "Publishing dockertemplate/bcmHostSnapshot as a public lxd image 'bcm-template' on cluster '$(lxc remote get-default)'."
            lxc publish dockertemplate/bcmHostSnapshot --alias bcm-template --public
        else
            echo "Publishing dockertemplate/bcmHostSnapshot as non-public lxd image cluster '$(lxc remote get-default)'."
            lxc publish dockertemplate/bcmHostSnapshot --alias bcm-template
        fi
    fi
fi
