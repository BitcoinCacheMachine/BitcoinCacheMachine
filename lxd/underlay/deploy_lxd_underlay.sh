#!/bin/bash

# create underlay from the snapshot
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

#apply the dockerd config which ties dockerd to 192.168.0.1
lxc file push dockerd.json underlay/etc/docker/daemon.json

lxc start underlay

sleep 15

lxc exec underlay -- ifmetric eth1 25
lxc exec underlay -- docker swarm init --advertise-addr 127.0.0.1 --listen-addr 127.0.0.1:2377 --data-path-addr 192.168.0.1 >/dev/null




# deploy the docker stack.
bash -c $BCM_LOCAL_GIT_REPO/docker_stacks/underlay/dnsmasq/up_lxd_dnsmasq.sh

#bash -c $BCM_LOCAL_GIT_REPO/docker_stacks/common/squid/up_lxd_squid.sh


if [[ $BCM_UNDERLAY_ENABLE_IP_FORWARDING = "true" ]]; then
    # let's start underlay so we can update some file permissions.
    # ufw firewall policy rules
    lxc exec underlay -- ufw allow in on eth2 proto tcp to any port 443
    lxc exec underlay -- ufw allow in on eth2 proto tcp to any port 80
    lxc exec underlay -- ufw allow in on eth2 proto tcp to any port 53
    lxc exec underlay -- ufw allow in on eth2 proto udp to any port 53
    lxc exec underlay -- ufw allow in on eth2 proto udp to any port 67
fi