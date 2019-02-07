#!/bin/bash

set -Eeu

sudo apt-get remove lxd lxd-client -y
sudo apt-get autoremove -y
sudo apt-get install tor wait-for-it -y

# remove any legacy lxd software and install install lxd via snap
if ! snap list | grep -q lxd; then
    sudo snap install lxd --stable
fi

# if the lxd groups doesn't exist, create it.
if ! grep -q lxd /etc/group; then
    sudo addgroup --system lxd
fi

if groups "$USER" | grep -q lxd; then
    sudo adduser "${USER}" lxd
    sudo gpasswd -a "${USER}" lxd
fi

sudo snap restart lxd

# run lxd init using the prepared preseed.
cat "$BCM_TEMP_DIR/provisioning/lxd_preseed.yml" | sudo lxd init --preseed

wait-for-it -t 30 localhost:8443