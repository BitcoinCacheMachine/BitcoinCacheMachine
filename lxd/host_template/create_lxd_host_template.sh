#!/bin/bash

set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# only execute if bcm_data is non-zero
if [[ $(lxc image list | grep "bcm-bionic-base") ]]; then
    # initialize the LXD container to the active lxd endpoint. 
    lxc init bcm-bionic-base -p default -p docker_priv -s bcm_data dockertemplate
    lxc config set dockertemplate limits.cpu 4
    lxc config set dockertemplate limits.memory 4GB
    lxc start dockertemplate
fi

sleep 5

# install docker - the script get-docker.sh does an apt-get update
lxc file push get-docker.sh dockertemplate/root/get-docker.sh
lxc exec dockertemplate -- sh get-docker.sh >/dev/null

# TODO provide configuration item to route these requests over local TOR proxy
echo "Installing required software on dockertemplate."
lxc exec dockertemplate -- apt-get install wait-for-it tor jq curl ifmetric slurm tcptrack -y
lxc exec dockertemplate -- apt-get autoclean
lxc exec dockertemplate -- apt-get check
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

