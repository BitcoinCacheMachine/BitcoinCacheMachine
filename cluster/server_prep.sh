#!/bin/bash

# this script preps a NEW server device (Ubuntu 18.04 >) to listen for incoming SSH
# connections on all interfaces and at an onion site (for remote administration). The
# server SHOULD exist BEHIND a NAT device with no port forwarding.

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y tor openssh-server avahi-daemon stubby
sudo apt-get remove lxd lxd-client -y
sudo apt-get autoremove -y

# if the lxd group doesn't exist, create it.
if ! grep -q lxd /etc/group; then
    sudo addgroup --system lxd
fi

if ! groups bcm | grep -q lxd; then
    sudo useradd -g lxd -m bcm
fi

if [[ ! -d /home/bcm/.ssh ]]; then
    sudo mkdir -p /home/bcm/.ssh
fi

if [[ ! -f /home/bcm/.ssh/authorized_keys ]]; then
    sudo touch /home/bcm/.ssh/authorized_keys
fi

sudo touch /etc/sudoers.d/bcm
echo "bcm ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/bcm

# todo add ability to interactively select management interface (if multiple)
if ! grep -Fxq "ListenAddress 0.0.0.0" /etc/ssh/sshd_config; then
    echo "ListenAddress 0.0.0.0" | sudo tee -a /etc/ssh/sshd_config
    sudo systemctl restart ssh
fi

if ! grep -Fxq "HiddenServiceDir /var/lib/tor/ssh/" /etc/tor/torrc; then
    echo "HiddenServiceDir /var/lib/tor/ssh/" | sudo tee -a /etc/tor/torrc
    echo "HiddenServicePort 22 127.0.0.1:22" | sudo tee -a /etc/tor/torrc
    echo "HiddenServiceAuthorizeClient stealth $(hostname)_ssh" | sudo tee -a /etc/tor/torrc
    sudo systemctl restart tor
    sleep 5
fi

if [[ -f /var/lib/tor/ssh/hostname ]]; then
    echo "SSH ONION SITE & AUTH TOKEN:"
    echo "  $(sudo cat /var/lib/tor/ssh/hostname)"
fi
