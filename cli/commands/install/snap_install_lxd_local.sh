#!/bin/bash

set -Eeuo pipefail


# if the lxd groups doesn't exist, create it.
if ! grep -q lxd /etc/group; then
    sudo addgroup --system lxd
fi

if groups "$USER" | grep -q lxd; then
    sudo adduser "${USER}" lxd
    sudo gpasswd -a "${USER}" lxd
fi

# remove any legacy lxd software and install install lxd via snap (we're really only using the client at this point.)
if ! snap list | grep -q lxd; then
    sudo snap install lxd --channel=candidate
fi

#sudo snap restart lxd