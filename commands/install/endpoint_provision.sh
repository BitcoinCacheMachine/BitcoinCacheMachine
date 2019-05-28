#!/bin/bash

set -Eeu
cd "$(dirname "$0")"

apt-get update -y
apt-get upgrade -y
sudo apt-get remove lxd lxd-client -y
sudo apt-get autoremove -y
sudo apt-get install --no-install-recommends tor wait-for-it -y

# install lxd via snap
if [ ! -x "$(command -v lxd)" ]; then
    # unless this is modified, we get snapshot creation in snap when removing lxd.
    sudo snap install lxd --channel=candidate
    sudo snap set system snapshots.automatic.retention=no
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
