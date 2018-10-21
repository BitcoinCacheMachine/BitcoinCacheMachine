#!/usr/bin/env bash

mkdir -p /tmp/bcm

sudo apt-get update

# first let's install docker-ce
# get-docker.sh is the one from https://get.docker.com/
bash -c $BCM_LOCAL_GIT_REPO/lxd/host_template/get-docker.sh

# delete our temp files
rm -Rf /tmp/bcm

# Next make sure multipass is installed so we can run type-1 VMs
if [[ ! $(snap list | grep multipass) ]]; then
    # if it doesn't, let's install
    sudo snap install multipass --beta --classic
fi

# next install LXD/LXC so we can test locally
sudo apt install -f zfsutils-linux

sudo snap install lxd --candidate

# and install client tools; TODO move these to a docker container running on the admin machine
sudo apt-get install -f wait-for-it rsync apg libfuse-dev fuse
