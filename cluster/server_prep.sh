#!/bin/bash

set -e

# this script preps a NEW server device (Ubuntu 18.04 >) to listen for incoming SSH
# connections on all interfaces and at an onion site (for remote administration). The
# server SHOULD exist BEHIND a NAT device with no port forwarding.

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y tor openssh-server avahi-daemon iotop curl socat
# TODO dnscrypt-proxy
sudo apt-get remove lxd lxd-client -y
sudo apt-get autoremove -y


# sudo -s

# curl -o $HOME/dnscrypt-proxy-linux_x86_64-2.0.21.tar.gz https://github.com/jedisct1/dnscrypt-proxy/releases/download/2.0.21/dnscrypt-proxy-linux_x86_64-2.0.21.tar.gz
# tar -xf - $HOME/dnscrypt-proxy-linux_x86_64-2.0.21.tar.gz -C /opt/dnscrypt-proxy

# systemctl stop systemd-resolved
# systemctl mask systemd-resolved



# echo "server_names = ['cloudflare', 'cloudflare-ipv6']" | sudo tee -a /etc/dnscrypt-proxy/dnscrypt-proxy.conf
# echo "listen_addresses = ['127.0.0.1:53', '[::1]:53']" | sudo tee -a /etc/dnscrypt-proxy/dnscrypt-proxy.conf

# # install the cloudflare DNS over TLS binary
# curl -o cloudflared.deb https://bin.equinox.io/c/VdrWdbjqyF/cloudflared-stable-linux-amd64.deb
# sudo dpkg -i cloudflared.deb

# # disable the systemd stub resovler
# sudo systemctl disable systemd-resolved.service
# sudo systemctl stop systemd-resolved
# sudo rm /etc/resolv.conf
# #sudo service network-manager restart
# echo "DNSStubListener=no" | sudo tee -a /etc/systemd/resolved.conf
# sudo systemctl disable systemd-resolved
# sudo systemctl stop systemd-resolved


# # forward local DNS UDP queries to TCP
# PORT=853; socat TCP4-LISTEN:${PORT},reuseaddr,fork SOCKS4A:127.0.0.1:dns4torpnlfs2ifuz2s2yf3fc7rdmsbhm6rw75euj35pac6ap25zgqad.onion:${PORT},socksport=9050

# sudo cloudflared proxy-dns
# sudo mkdir -p /usr/local/etc/cloudflared
# cat << EOF > /usr/local/etc/cloudflared/config.yml
# proxy-dns: true
# proxy-dns-upstream:
#  - https://1.1.1.1/dns-query
#  - https://1.0.0.1/dns-query
# EOF
# sudo cloudflared service install


# if the lxd group doesn't exist, create it.
if ! grep -q lxd /etc/group; then
    sudo addgroup --system lxd
fi

if ! groups bcm | grep -q lxd; then
    sudo useradd -g lxd -g sudo -m bcm
fi

if [[ ! -d /home/bcm/.ssh ]]; then
    sudo mkdir -p /home/bcm/.ssh
fi

if [[ ! -f /home/bcm/.ssh/authorized_keys ]]; then
    sudo touch /home/bcm/.ssh/authorized_keys
    sudo chown bcm:lxd -R /home/bcm/.ssh
fi

sudo touch /etc/sudoers.d/bcm
echo "bcm ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers.d/bcm

# update /etc/ssh/sshd_config to listen for incoming SSH connections on all interfaces.
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
