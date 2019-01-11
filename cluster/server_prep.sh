#!/bin/bash

# this script preps a NEW server device (Ubuntu 18.04 >) to
# listen for incoming SSH connections on all interfaces and
# at an onion site (for remote administration).

sudo apt-get install -y tor openssh-server

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

if ! grep -Fxq "HiddenServiceDir /var/lib/tor/lxd/" /etc/tor/torrc; then
	echo "HiddenServiceDir /var/lib/tor/lxd/" | sudo tee -a /etc/tor/torrc
	echo "HiddenServicePort 8443 127.0.0.1:8443" | sudo tee -a /etc/tor/torrc
	echo "HiddenServiceAuthorizeClient stealth $(hostname)_lxd" | sudo tee -a /etc/tor/torrc
	sudo systemctl restart tor
fi

echo "SSH ONION SITE & AUTH TOKEN: $(sudo cat /var/lib/tor/ssh/hostname)"

echo "LXD ONION SITE & AUTH TOKEN: $(sudo cat /var/lib/tor/lxd/hostname)"
