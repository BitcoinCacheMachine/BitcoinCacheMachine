#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"


sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install --no-install-recommends -y openssh-server iotop curl socat wait-for-it

# note that we remove the basic tor client in lieu of the distributed binary
# which tends to be more up-to-date and have more v3 features and reliability.
# and we prefer snap-based lxd.
sudo apt-get remove lxd lxd-client tor -y
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

if ! groups | grep -q lxd; then
    sudo useradd -g lxd -g sudo -m $(whoami)
fi

if [[ ! -f "$HOME/.ssh/authorized_keys" ]]; then
    sudo touch "$HOME/.ssh/authorized_keys"
    sudo chown $(whoami):lxd -R "$HOME/.ssh"
fi

# TODO verify where we need this.
sudo touch /etc/sudoers.d/$USERNAME
echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" | sudo tee -a "/etc/sudoers.d/$USERNAME"

# update /etc/ssh/sshd_config to listen for incoming SSH connections on all interfaces.
if ! grep -Fxq "ListenAddress 0.0.0.0" /etc/ssh/sshd_config; then
    {
        echo "ListenAddress 127.0.0.1"
        echo "ListenAddress 0.0.0.0"
    } | sudo tee -a /etc/ssh/sshd_config
fi

sudo systemctl restart ssh
wait-for-it -t 15 127.0.0.1:22


# if ! grep -Fxq "HiddenServiceDir /var/lib/tor/ssh/" /etc/tor/torrc; then
#     echo ""  | sudo tee /etc/tor/torrc
#     # {
#     #     echo "SocksPort 9050"
#     #     echo "HiddenServiceDir /var/lib/tor/ssh/"
#     #     echo "HiddenServiceVersion 3"
#     #     echo "HiddenServicePort 22 127.0.0.1:22"
#     # } | sudo tee /etc/tor/torrc
# fi

wait-for-it -t 30 127.0.0.1:9050
