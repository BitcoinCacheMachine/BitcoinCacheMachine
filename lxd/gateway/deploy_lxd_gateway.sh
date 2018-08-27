#!/bin/bash

# create gateway from the snapshot
lxc copy gateway-template/gatewaySnapshot gateway

# ensure the host_template is available.
echo "Creating a dockervol for 'gateway'."
bash -c "../shared/create_dockervol.sh gateway"


#lxc profile device set gatewayprofile eth1 nictype physical
echo "Setting lxc profile 'gatewayprofile' eth1 (untrusted outside) to macvlan on physical interface '$BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE'."
lxc profile device set gatewayprofile eth1 parent $BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE

#lxc profile device set gatewayprofile eth2 nictype physical
echo "Setting lxc profile 'gatewayprofile' eth2 (trusted inside) parent to capture the physical interface '$BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE'."
lxc profile device set gatewayprofile eth2 parent $BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE

lxc profile apply gateway default,bcm_disk,docker_priv,gatewayprofile

#apply the dockerd config which ties dockerd to 192.168.0.1
lxc file push dockerd.json gateway/etc/docker/daemon.json

lxc start gateway

sleep 15

lxc exec gateway -- ifmetric eth1 25
lxc exec gateway -- docker swarm init --advertise-addr 127.0.0.1 --listen-addr 127.0.0.1:2377 --data-path-addr 192.168.0.1 >/dev/null




# deploy the docker stack.
bash -c $BCM_LOCAL_GIT_REPO/docker_stacks/gateway/dnsmasq/up_lxd_dnsmasq.sh

#bash -c $BCM_LOCAL_GIT_REPO/docker_stacks/common/squid/up_lxd_squid.sh


if [[ $BCM_GATEWAY_ENABLE_IP_FORWARDING = "true" ]]; then
    # let's start gateway so we can update some file permissions.
    # ufw firewall policy rules
    lxc exec gateway -- ufw allow in on eth2 proto tcp to any port 443
    lxc exec gateway -- ufw allow in on eth2 proto tcp to any port 80
    lxc exec gateway -- ufw allow in on eth2 proto tcp to any port 53
    lxc exec gateway -- ufw allow in on eth2 proto udp to any port 53
    lxc exec gateway -- ufw allow in on eth2 proto udp to any port 67
fi