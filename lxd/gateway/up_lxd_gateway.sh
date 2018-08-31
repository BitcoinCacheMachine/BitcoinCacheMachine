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

# now check inside
if [[ -z $(lxc network list | grep $BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE) ]]; then
    echo "Error. Physical interface '$BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE' doesn't exist on LXD host $(lxc remote get-default). Please update BCM environment variable BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE."
    exit
fi

# create and populate the required networks
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/create_lxc_network_bridge_nat.sh $BCM_GATEWAY_NETWORKS_CREATE lxdbrGateway"


# create an bcm-gateway-profile
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/create_lxc_profile.sh $BCM_GATEWAY_PROFILE_GATEWAYPROFILE_CREATE bcm-gateway-profile $BCM_LOCAL_GIT_REPO/lxd/gateway/gateway_lxd_profile.yml"

# then update the profile with the user-specified interface
echo "Setting lxc profile 'bcm-gateway-profile' eth1 to host interface '$BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE'."
lxc profile device set bcm-gateway-profile eth1 parent $BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE

# create a gateway template if it doesn't exist.
if [[ -z $(lxc list | grep "bcm-gateway") ]]; then
    # let's generate a LXC template to base our lxc container on.
    lxc init bcm-template bcm-gateway -p bcm_disk -p docker_privileged -p bcm-gateway-profile
fi

# create the docker backing for 'bcm-gateway'
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/create_attach_lxc_storage_to_container.sh $BCM_GATEWAY_STORAGE_DOCKERVOL_CREATE bcm-gateway bcm-gateway-dockervol"

lxc file push 10-lxc.yaml bcm-gateway/etc/netplan/10-lxc.yaml

sleep 5

lxc start bcm-gateway

sleep 15

# lxc exec bcm-gateway -- apt-get install -y ufw
# lxc file push ufw_before.rules bcm-gateway/etc/ufw/before.rules
# lxc file push ufw_sysctl.conf bcm-gateway/etc/ufw/sysctl.conf

# lxc exec bcm-gateway -- mkdir -p /etc/default
# lxc file push ufw.conf bcm-gateway/etc/default/ufw

# lxc exec bcm-gateway -- chown root:root /etc/ufw/before.rules
# lxc exec bcm-gateway -- chmod 0640 /etc/ufw/before.rules
# lxc exec bcm-gateway -- chown root:root /etc/ufw/sysctl.conf
# lxc exec bcm-gateway -- chmod 0644 /etc/ufw/sysctl.conf

# lxc exec bcm-gateway -- chown root:root /etc/default/ufw
# lxc exec bcm-gateway -- chmod 0644 /etc/default/ufw
# #lxc exec bcm-gateway -- ifmetric eth0 25

bash -c "$BCM_LOCAL_GIT_REPO/docker_images/gateway/build_gateway.sh bcm-gateway"

lxc file push resolved.conf bcm-gateway/etc/systemd/resolved.conf
lxc exec bcm-gateway -- chown root:root /etc/systemd/resolved.conf
lxc exec bcm-gateway -- chmod 0644 /etc/systemd/resolved.conf

# lxc exec bcm-gateway -- ufw allow in on eth1 proto tcp to any port 9050 #OUTBOUND TOR
# lxc exec bcm-gateway -- ufw allow in on eth1 proto tcp to any port 3128 #HTTP/HTTPS
# lxc exec bcm-gateway -- ufw allow in on eth1 proto tcp to any port 53 #DNS
# lxc exec bcm-gateway -- ufw allow in on eth1 proto udp to any port 53 #DNS
# lxc exec bcm-gateway -- ufw allow in on eth1 proto udp to any port 67 #DHCP
# lxc exec bcm-gateway -- ufw allow in on eth1 proto udp to any port 69 #TFTP
# lxc exec bcm-gateway -- ufw enable


lxc stop bcm-gateway
lxc snapshot bcm-gateway gatewaySnapshot


# #systemd binds to 53 be default, remove it and let's use docker-hosted dnsmasq container
# # lxc exec bcm-gateway -- systemctl stop systemd-resolved
# # lxc exec bcm-gateway -- systemctl disable systemd-resolved

# disable systemd-resolved so we can run a DNS server locally.
lxc start bcm-gateway
sleep 15
lxc exec bcm-gateway -- docker run --name dnsmasq -d --restart always --net=host --cap-add=NET_ADMIN bcm-dnsmasq:latest

lxc exec bcm-gateway -- docker swarm init

bash -c "$BCM_LOCAL_GIT_REPO/docker_stacks/gateway/squid/up_lxd_squid.sh bcm-gateway"
