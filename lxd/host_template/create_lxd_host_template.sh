#!/bin/bash

# first, make sure the profiles exist and/or are up to date.
bash -c ./up_lxd_profiles.sh

# only execute if bcm_data is non-zero
if [[ $(lxc storage list | grep "bcm_data") ]]; then
    # initialize the LXD container to the active lxd endpoint. 
    lxc init ubuntu:18.04 -p default -p docker_priv -s bcm_data dockertemplate
    lxc config set dockertemplate limits.cpu 4
    lxc config set dockertemplate limits.memory 2GB
    lxc start dockertemplate
fi

sleep 5

# install docker - this does an 'apt-get update'
lxc file push ./get-docker.sh dockertemplate/root/get-docker.sh
lxc exec dockertemplate -- apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 7EA0A9C3F273FCD8
lxc exec dockertemplate -- sh get-docker.sh >/dev/null

# TODO provide configuration item to route these requests over local TOR proxy
echo "Installing required software on dockertemplate."
lxc exec dockertemplate -- apt-get install wait-for-it tor jq curl ifmetric slurm tcptrack -y
#lxd exec dockertemplate -- apt-get clean all
lxc exec dockertemplate -- rm -rf /tmp/*

# stop the current template dockerd instance since we're about to create a snapshot
# Enable the docker daemon to start by default.
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

echo "Creating a snapshot of the lxd host 'dockertemplate' called 'bcmHostSnapshot'."
lxc snapshot dockertemplate bcmHostSnapshot

# if instructed, serve the newly created snapshot to trusted LXD hosts.
if [[ $BCM_LXD_SERVE_DOCKER_TEMPLATE_IMAGE = "true" ]]; then
    # if the template doesn't exist, publish it create it.
    if [[ -z $(lxc image list | grep bctemplate) ]]; then
        echo "Publishing dockertemplate/bcmHostSnapshot snapshot as 'bctemplate' lxd image."
        lxc publish dockertemplate/bcmHostSnapshot --alias bctemplate
    fi
fi