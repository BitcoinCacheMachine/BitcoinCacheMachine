#!/bin/bash

#set -Eeuo

sudo apt-get remove lxd lxd-client -y
sudo apt-get autoremove -y

# remove any legacy lxd software and install install lxd via snap
if ! snap list | grep -q lxd; then
	sudo snap install lxd --candidate
	sleep 10
fi

# if the lxd groups doesn't exist, create it.
if ! grep -q lxd /etc/group; then
	sudo addgroup lxd
fi

if groups "$USER" | grep -q lxd; then
	sudo gpasswd -a "${USER}" lxd
fi

sudo snap restart lxd

sleep 15

sudo bash -c "cat $HOME/bcm/lxd_preseed.yml | sudo lxd init --preseed"

sudo rm -rf "$HOME/bcm/"
