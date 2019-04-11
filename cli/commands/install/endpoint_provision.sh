#!/bin/bash

set -Eeux
cd "$(dirname "$0")"

sudo apt-get remove lxd lxd-client -y
sudo apt-get autoremove -y
sudo apt-get install tor wait-for-it -y

# install lxd via snap
if [ ! -x "$(command -v lxd)" ]; then
    sudo snap install lxd --channel=candidate
fi

# if the 'bcm' user doesn't exist, let's create it and add it
# to the NOPASSWD sudoers list (like we have in cloud-init provisioned machines)
if groups "$USER" | grep -q lxd; then
    sudo adduser bcm
    sudo gpasswd -a "${USER}" lxd
fi

sudo snap restart lxd

# run lxd init using the prepared preseed.
cat "./lxd_preseed.yml" | sudo lxd init --preseed

wait-for-it -t 30 127.0.0.1:8443
