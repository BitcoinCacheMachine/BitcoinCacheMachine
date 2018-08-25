#!/bin/bash

# WARNING, this script ASSUMES that the LXD daemon is either 1) running on the same host
# from which the script is being run (i.e., localhost). You can also provision Cache Stack
# to a remote LXD daemon by setting your local LXC client to use the specified remote LXD service
# You can use 'lxc remote add hostname hostname:8443 --accept-certificates to add a remote LXD'
# endpoint to your client.

# exit script if there's an error anywhere
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# get the current directory where this script is so we can reference it later.
SCRIPT_DIR=$(pwd)

# create the lxdbrUnderlay network if it doesn't exist.
if [[ -z $(lxc network list | grep lxdbrUnderlay) ]]; then
    # a bridged network network for mgmt and outbound NAT by hosts.
    lxc network create lxdbrUnderlay ipv4.nat=true
else
    echo "lxdbrUnderlay already exists."
fi

# create the underlayprofile profile if it doesn't exist.
if [[ -z $(lxc profile list | grep underlayprofile) ]]; then
    lxc profile create underlayprofile
fi

echo "Applying ./underlay_lxd_profile.yml to lxd profile 'underlayprofile'."
cat ./underlay_lxd_profile.yml | lxc profile edit underlayprofile

# create the underlay container if it doesn't exist
if [[ -z $(lxc list | grep underlay-template) ]]; then
    #lxc init ubuntu:18.04 -p default -p underlayprofile -s bcm_data underlay
    if [[ $BCM_LXD_EXTERNAL_BCTEMPLATE_REMOTE = "none" ]] ; then
        #lxc init bctemplate underlay -p default -p docker_priv -p underlayprofile -s bcm_data
        lxc copy dockertemplate/bcmHostSnapshot underlay-template
    else
        lxc init $BCM_LXD_EXTERNAL_BCTEMPLATE_REMOTE:bctemplate underlay-template
    fi
else
  echo "LXC container 'underlay-template' already exists."
fi

sleep 5

lxc profile apply underlay-template default,docker_priv
#lxc file push ./ufw.conf underlay/etc/default/ufw
#lxc exec underlay -- chown root:root /etc/default/ufw
# lxc exec underlay -- chmod 0644 /etc/systemd/resolved.conf
# lxc exec underlay -- chown root:root /etc/systemd/resolved.conf

# disable systemd-resolved so we can run a DNS server locally.
lxc file push ./resolved.conf underlay-template/etc/systemd/resolved.conf

# to set interface metrics
#lxc file push ./dhcpd.conf underlay-template/etc/dhcpd.conf

# ufw firewall policy rules
# lxc file push ./ufw_before.rules underlay-template/etc/ufw/before.rules
# lxc file push ./ufw_sysctl.conf underlay-template/etc/ufw/sysctl.conf
# lxc file push ./ufw.conf underlay-template/etc/default/ufw

# let's start underlay so we can update some file permissions.
lxc start underlay-template



#lxc exec underlay-template -- chown root:root /etc/dhcpd.conf
#lxc exec underlay-template -- chmod 0640 /etc/dhcpd.conf

# lxc exec underlay-template -- chown root:root /etc/ufw/before.rules
# lxc exec underlay-template -- chmod 0640 /etc/ufw/before.rules

# lxc exec underlay-template -- chown root:root /etc/ufw/sysctl.conf
# lxc exec underlay-template -- chmod 0644 /etc/ufw/sysctl.conf

# lxc exec underlay-template -- chown root:root /etc/default/ufw
# lxc exec underlay-template -- chmod 0644 /etc/default/ufw

# lxc exec underlay-template -- ufw enable

# start tor on startup
#lxc exec underlay-template -- systemctl enable tor

lxc stop underlay-template
    # so we can restore to a good known state.
lxc snapshot underlay-template underlaySnapshot

lxc copy underlay-template/underlaySnapshot underlay

# ensure the host_template is available.
echo "Creating a dockervol for 'underlay'."
bash -c "../shared/create_dockervol.sh underlay"

#lxc profile device set underlayprofile eth1 nictype physical
echo "Setting lxc profile 'underlayprofile' eth1 (untrusted outside) to macvlan on physical interface '$BCM_UNDERLAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE'."
lxc profile device set underlayprofile eth1 parent $BCM_UNDERLAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE

#lxc profile device set underlayprofile eth2 nictype physical
echo "Setting lxc profile 'underlayprofile' eth2 (trusted inside) parent to capture the physical interface '$BCM_UNDERLAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE'."
lxc profile device set underlayprofile eth2 parent $BCM_UNDERLAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE

lxc profile apply underlay default,bcm_disk,docker_priv,underlayprofile

# apply the dockerd config which ties dockerd to 192.168.0.1
#lxc file push ./dockerd.json underlay/etc/docker/daemon.json

lxc start underlay

sleep 15

lxc exec underlay -- ifmetric eth1 25
lxc exec underlay -- docker swarm init --advertise-addr 127.0.0.1 --listen-addr 127.0.0.1:2377 --data-path-addr 192.168.0.1

# make sure TOR is running so DNS goes over TOR
bash -c $BCM_LOCAL_GIT_REPO/docker_images/underlay/build_underlay.sh

# lxc exec underlay -- ufw allow in on eth2 proto tcp to any port 443
# lxc exec underlay -- ufw allow in on eth2 proto tcp to any port 53
# lxc exec underlay -- ufw allow in on eth2 proto udp to any port 53
# lxc exec underlay -- ufw allow in on eth2 proto udp to any port 67

bash -c ./stacks/dnsmasq/up_lxd_dnsmasq.sh


# --net=host
#lxc exec underlay -- docker run --name dnsmasq --rm -d --cap-add=NET_ADMIN bcm-dnsmasq:latest dnsmasq -d

#systemd binds to 53 be default, remove it and let's use docker-hosted dnsmasq container
lxc exec underlay -- systemctl stop systemd-resolved
lxc exec underlay -- systemctl disable systemd-resolved






# # # BCM SPECIFIC RULES
# # # allow DHCP requests from 192.168.0.0/24
# # -A ufw-before-input -s 192.168.0.0/24 -p udp --dport 67 -j ACCEPT

# # ## allow DNS queries (tcp for larger requests)
# # -A ufw-before-input -s 192.168.0.0/24 -p tcp --dport 53 -j ACCEPT
# # -A ufw-before-input -s 192.168.0.0/24 -p udp --dport 53 -j ACCEPT