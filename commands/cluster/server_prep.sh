#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

sudo apt-get install --no-install-recommends -y openssh-server iotop curl socat wait-for-it
sudo apt-get remove lxd lxd-client -y
sudo apt-get autoremove -y

# if the lxd group doesn't exist, create it.
if ! grep -q lxd /etc/group; then
    sudo addgroup --system lxd
fi

if ! groups | grep -q lxd; then
    sudo useradd -g lxd -g sudo -m "$(whoami)"
fi

if [[ ! -f "$HOME/.ssh/authorized_keys" ]]; then
    sudo touch "$HOME/.ssh/authorized_keys"
    sudo chown "$(whoami):lxd" -R "$HOME/.ssh"
fi

# TODO verify where we need this.
sudo touch "/etc/sudoers.d/$(whoami)"
echo "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo tee -a "/etc/sudoers.d/$(whoami)"

# update /etc/ssh/sshd_config to listen for incoming SSH connections on all interfaces.
if ! grep -Fxq "ListenAddress 0.0.0.0" /etc/ssh/sshd_config; then
    {
        echo "ListenAddress 127.0.0.1"
        echo "ListenAddress 0.0.0.0"
    } | sudo tee -a /etc/ssh/sshd_config
fi

sudo systemctl restart ssh
wait-for-it -t 15 127.0.0.1:22

