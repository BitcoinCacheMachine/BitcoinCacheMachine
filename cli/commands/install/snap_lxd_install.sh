#!/bin/bash

set -Eeuox

sudo apt-get remove lxd lxd-client -y
sudo apt-get autoremove -y

# remove any legacy lxd software and install install lxd via snap
if ! snap list | grep -q lxd; then
	sudo snap install lxd --candidate
fi

# if the lxd groups doesn't exist, create it.
if ! grep -q lxd /etc/group; then
	sudo addgroup --system lxd
fi

if groups "$USER" | grep -q lxd; then
	sudo gpasswd -a "${USER}" lxd
fi

sudo snap restart lxd
