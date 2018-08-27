#!/bin/bash

set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# before we even continue, ensure the appropriate ports actually exist.
if [[ -z $(lxc network list | grep $BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE) ]]; then
    echo "Error. Physical interface '$BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE' doesn't exist on LXD host '$(lxc remote get-default)'. Please update BCM environment variable BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE."
    exit
fi

# now check inside
if [[ -z $(lxc network list | grep $BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE) ]]; then
    echo "Error. Physical interface '$BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE' doesn't exist on LXD host '$(lxc remote get-default)'. Please update BCM environment variable BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE."
    exit
fi

# create gateway from the snapshot
lxc copy gateway-template/gatewaySnapshot bcm-gateway

bash -c ./create_lxd_gateway_profiles.sh

#lxc profile device set gatewayprofile eth1 nictype physical
echo "Setting lxc profile 'gatewayprofile' eth1 (untrusted outside) to macvlan on physical interface '$BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE'."
lxc profile device set gatewayprofile eth1 parent $BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE

#lxc profile device set gatewayprofile eth2 nictype physical
echo "Setting lxc profile 'gatewayprofile' eth2 (trusted inside) parent to capture the physical interface '$BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE'."
lxc profile device set gatewayprofile eth2 parent $BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE

# apply the profiles to bcm-gateway
lxc profile apply bcm-gateway bcm_disk,docker_priv,gatewayprofile

#apply the dockerd config which ties dockerd to 192.168.0.1
lxc file push dockerd.json bcm-gateway/etc/docker/daemon.json

lxc start bcm-gateway

sleep 15

lxc exec bcm-gateway -- ifmetric eth1 25
lxc exec bcm-gateway -- docker swarm init --advertise-addr 127.0.0.1 --listen-addr 127.0.0.1:2377 --data-path-addr 192.168.0.1 >/dev/null




# deploy the docker stack.
bash -c $BCM_LOCAL_GIT_REPO/docker_stacks/gateway/dnsmasq/up_lxd_dnsmasq.sh

#bash -c $BCM_LOCAL_GIT_REPO/docker_stacks/common/squid/up_lxd_squid.sh


if [[ $BCM_GATEWAY_ENABLE_IP_FORWARDING = "true" ]]; then
    # let's start gateway so we can update some file permissions.
    # ufw firewall policy rules
    lxc exec bcm-gateway -- ufw allow in on eth2 proto tcp to any port 443
    lxc exec bcm-gateway -- ufw allow in on eth2 proto tcp to any port 80
    lxc exec bcm-gateway -- ufw allow in on eth2 proto tcp to any port 53
    lxc exec bcm-gateway -- ufw allow in on eth2 proto udp to any port 53
    lxc exec bcm-gateway -- ufw allow in on eth2 proto udp to any port 67
fi