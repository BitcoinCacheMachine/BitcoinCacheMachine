#!/bin/bash

# this script preps a NEW server device (Ubuntu 18.04 >) to listen for incoming SSH
# connections on all interfaces and at an onion site (for remote administration). The
# server SHOULD exist BEHIND a NAT device with no port forwarding.

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y tor openssh-server
sudo apt-get remove lxd lxd-client -y

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
fi

if [[ -f /var/lib/tor/ssh/hostname ]]; then
    echo "SSH ONION SITE & AUTH TOKEN:"
    echo "  $(sudo cat /var/lib/tor/ssh/hostname)"
else
    echo "TOR endpoint information unavailable."
fi