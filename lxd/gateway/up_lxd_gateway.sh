#!/bin/bash

set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# call bcm_script_before.sh to perform the things that every BCM script must do prior to proceeding
bash -c $BCM_LOCAL_GIT_REPO/resources/bcm/bcm_script_before.sh

# if bcm-template lxc image exists, run the gateway template creation script.
if [[ -z $(lxc image list | grep "bcm-template") ]]; then
    echo "Required LXC image 'bcm-template' does not exist! Ensure your current LXD remote $(lxc remote get-default) creates or downloads a remote 'bcm-template'."
    exit 1
fi


# before we even continue, ensure the appropriate ports actually exist.
if [[ -z $(lxc network list | grep $BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE) ]]; then
    echo "Error. Physical interface '$BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE' doesn't exist on LXD host '$(lxc remote get-default)'. Please update BCM environment variable BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE."
    exit
fi

# now check inside
if [[ -z $(lxc network list | grep $BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE) ]]; then
    echo "Error. Physical interface '$BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE' doesn't exist on LXD host $(lxc remote get-default). Please update BCM environment variable BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE."
    exit
fi


# create and populate the required networks
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/create_lxc_network_bridge_nat.sh $BCM_GATEWAY_NETWORKS_CREATE lxdbrGateway"


# create an populate necessary profiles
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/create_lxc_profile.sh $BCM_GATEWAY_PROFILE_GATEWAYPROFILE_CREATE bcm-gateway-profile $BCM_LOCAL_GIT_REPO/lxd/gateway/gateway_lxd_profile.yml"

# create a gateway template if it doesn't exist.
if [[ -z $(lxc list | grep "gateway-template") ]]; then
    # let's generate a LXC template to base our lxc container on.
    bash -c ./create_lxd_gateway-template.sh
fi


if [[ $BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE = "default" ]] || [[ $BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE = "default" ]]; then
    echo "Please configure the BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE and BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE environment variables in your '~/.bcm/endpoints/$(lxc remote get-default).env'"
    exit
fi


# create gateway from the snapshot
lxc copy gateway-template/gatewaySnapshot bcm-gateway

# create the docker backing for 'bcm-gateway'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/create_attach_lxc_storage_to_container.sh $BCM_GATEWAY_STORAGE_DOCKERVOL_CREATE bcm-gateway bcm-gateway-dockervol"

#lxc profile device set bcm-gateway-profile eth1 nictype physical
echo "Setting lxc profile 'bcm-gateway-profile' eth1 (untrusted outside) to macvlan on physical interface '$BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE'."
lxc profile device set bcm-gateway-profile eth1 parent $BCM_GATEWAY_PHYSICAL_UNTRUSTED_OUTSIDE_INTERFACE

#lxc profile device set bcm-gateway-profile eth2 nictype physical
echo "Setting lxc profile 'bcm-gateway-profile' eth2 (trusted inside) parent to capture the physical interface '$BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE'."
lxc profile device set bcm-gateway-profile eth2 parent $BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE

# apply the profiles to bcm-gateway
lxc profile apply bcm-gateway ''
lxc profile apply bcm-gateway docker_privileged,bcm-gateway-profile

#lxc file push dockerd.json bcm-gateway/etc/docker/daemon.json

lxc start bcm-gateway

#sleep 15

# lxc exec bcm-gateway -- ifmetric eth1 25

# #lxc exec bcm-gateway -- docker swarm init --advertise-addr 127.0.0.1 --listen-addr 127.0.0.1:2377 --data-path-addr 192.168.0.1 >/dev/null


# # build the necessary images
# bash -c "$BCM_LOCAL_GIT_REPO/docker_images/gateway/build_gateway.sh bcm-gateway"

# # #bash -c $BCM_LOCAL_GIT_REPO/docker_stacks/common/squid/up_lxd_squid.sh


# # #systemd binds to 53 be default, remove it and let's use docker-hosted dnsmasq container
# # # lxc exec bcm-gateway -- systemctl stop systemd-resolved
# # # lxc exec bcm-gateway -- systemctl disable systemd-resolved

# lxc exec bcm-gateway -- docker run --name dnsmasq -d --restart always --net=host --cap-add=NET_ADMIN bcm-dnsmasq:latest

# # if [[ $BCM_GATEWAY_ENABLE_IP_FORWARDING = "true" ]]; then
# #     # let's start gateway so we can update some file permissions.
# #     # ufw firewall policy rules
# #     lxc exec bcm-gateway -- ufw allow in on eth2 proto tcp to any port 443
# #     lxc exec bcm-gateway -- ufw allow in on eth2 proto tcp to any port 80
# #     lxc exec bcm-gateway -- ufw allow in on eth2 proto tcp to any port 53
# #     lxc exec bcm-gateway -- ufw allow in on eth2 proto udp to any port 53
# #     lxc exec bcm-gateway -- ufw allow in on eth2 proto udp to any port 67
# #     lxc exec bcm-gateway -- ufw allow in on eth2 proto udp to any port 67
# #     lxc exec bcm-gateway -- ufw enable
# # fi



# lxc stop bcm-gateway

# sleep 15

# lxc start bcm-gateway