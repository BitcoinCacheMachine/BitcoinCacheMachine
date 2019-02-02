#!/bin/bash

set -Eeu

sudo apt-get remove lxd lxd-client -y
sudo apt-get autoremove -y
sudo apt-get install tor -y

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
cat /tmp/bcm/provisioning/lxd_preseed.yml | sudo lxd init --preseed

wait-for-it -t 30 localhost:8443

# # ensure tor is installed and configure the daemon to expose LXD over authenticated tor onion site
# sudo apt-get install -y tor
# if ! grep -Fxq "HiddenServiceDir /var/lib/tor/lxd/" /etc/tor/torrc; then
#     echo "HiddenServiceDir /var/lib/tor/lxd/" | sudo tee -a /etc/tor/torrc
#     echo "HiddenServicePort 8443 127.0.0.1:8443" | sudo tee -a /etc/tor/torrc
#     echo "HiddenServiceAuthorizeClient stealth $(hostname)_lxd" | sudo tee -a /etc/tor/torrc
#     sudo systemctl restart tor
# fi

# # copy the tor_hostname for LXD to a readable file.
# if [[ -f /var/lib/tor/lxd/hostname ]]; then
#     sudo cp /var/lib/tor/lxd/hostname /tmp/lxd_tor_hostname
#     sudo chmod 0444 /tmp/lxd_tor_hostname
# else
#     echo "ERROR: TOR endpoint information unavailable."
# fi