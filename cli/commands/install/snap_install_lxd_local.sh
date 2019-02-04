#!/bin/bash

set -Eeu

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
