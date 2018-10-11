#!/bin/bash

mkdir -p /tmp/bcm

sudo apt-get update

# first let's install docker-ce
curl -fsSL get.docker.com -o /tmp/bcm/get-docker.sh
chmod +x /tmp/bcm/get-docker.sh
bash -c /tmp/bcm/get-docker.sh

# Next make sure multipass is installed so we can run type-1 VMs
if [[ ! $(snap list | grep multipass) ]]; then
    # if it doesn't, let's install
    sudo snap install multipass --beta --classic
fi

# next install LXD/LXC so we can test locally
sudo apt install -f zfsutils-linux lxd 

# and install client tools; TODO move these to a docker container running on the admin machine
sudo apt-get install -f wait-for-it rsync apg libfuse-dev fuse
