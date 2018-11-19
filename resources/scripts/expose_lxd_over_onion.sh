#!/bin/bash

# this script is run on a base operating system (via SSH for remote hosts) or locally in the terminal.
# it configures your system's LXD administrative interface to listen on an authenticated TOR hidden service

sudo su

sudo apt-get install tor -y

sudo mkdir -p /var/lib/tor/lxd
sudo chown debian-tor:debian-tor /var/lib/tor/lxd
sudo chmod 0600 /var/lib/tor

sudo echo "HiddenServiceDir /var/lib/tor/lxd/" >> /etc/tor/torrc
sudo echo "HiddenServicePort 8443 127.0.0.1:8443" >> /etc/tor/torrc
sudo echo "HiddenServiceAuthorizeClient stealth lxd" >> /etc/tor/torrc

sudo chown debian-tor:debian-tor /var/lib/tor/lxd
sudo chmod 0600 /var/lib/tor

systemctl restart tor


# we're going to set the LXD remote to LOCAL SINCE THIS SCRIPT IS MEANT TO BE RUN ON THE BASE HOST INTERACTIVELY
lxc remote switch local

lxc config set core.https_address '127.0.0.1:8444'