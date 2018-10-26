#!/usr/bin/env bash

set -eu

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# call bcm_script_before.sh to ensure we have up-to-date ENV variables.
source "$BCM_LOCAL_GIT_REPO/resources/export_bcm_envs.sh"

# if bcm-template lxc image exists, run the gateway template creation script.
if [[ -z $(lxc image list | grep "bcm-template") ]]; then
    echo "Required LXC image 'bcm-template' does not exist! Ensure your current LXD remote $(lxc remote get-default) creates or downloads a remote 'bcm-template'."
    return
fi

if [[ $BCM_GATEWAY_NETWORKS_CREATE = "true" ]]; then
    # create and populate the required networks
    bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/create_lxc_network_bridge_nat.sh lxdbrGateway basicnat"
fi

# create the 'bcm-gateway-profile' lxc profile
if [[ $BCM_GATEWAY_PROFILE_GATEWAYPROFILE_CREATE = "true" ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/create_lxc_profile.sh bcm-gateway-profile $BCM_LOCAL_GIT_REPO/lxd/gateway/gateway_lxd_profile.yml"
fi

#create and populate the required networks
if [[ $BCM_HOSTTEMPLATE_NETWORK_LXDBR0_CREATE = "true" ]]; then
    #bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/connect_container_to_underlay.sh"
    lxc network create lxdbrBCMNET 
fi

#### this is what we do when we are told to attach to physical network
if [[ $BCM_GATEWAY_ATTACH_TO_UNDERLAY == "true" ]]; then
    
    if [[ $BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE != "default" ]]; then
        # ensure the physical interface exists.
        if [[ -z $(lxc network list | grep $BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE) ]]; then
            echo "Error. Physical interface '$BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE' doesn't exist on LXD host $(lxc remote get-default). Please update BCM environment variable BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE."
            exit 1
        fi

        # then update the profile with the user-specified interface
        echo "Setting lxc profile 'bcm-gateway-profile' eth1 to host interface '$BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE'."
        lxc profile device set bcm-gateway-profile eth1 nictype physical
        lxc profile device set bcm-gateway-profile eth1 parent $BCM_GATEWAY_PHYSICAL_TRUSTED_INSIDE_INTERFACE
    fi    
else
    echo "BCM directed to perform a standalone deployment. LXC container '$BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME' will not attach to a physical interface."
fi

# create a gateway template if it doesn't exist.
if [[ -z $(lxc list | grep "$BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME") ]]; then
    # grab the bcm-template lxc image that's been prepared for us.
    lxc init bcm-template $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME -p bcm_disk -p docker_privileged -p bcm-gateway-profile
fi

lxc file push 10-lxc.yaml $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME/etc/netplan/10-lxc.yaml

lxc start $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME

bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/wait_for_dockerd.sh $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME"

lxc exec $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME -- apt-get install -y ufw tor
lxc file push torrc $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME/etc/tor/torrc


lxc exec $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME -- ufw allow in on localhost proto udp to any port 9053 # incoming DNS requests go over TOR
lxc exec $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME -- ufw allow in on eth1 proto tcp to any port 9050 # For TOR proxy (TODO)
lxc exec $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME -- ufw allow in on eth1 proto tcp to any port 3128 # HTTPS squid proxy
#lxc exec $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME -- ufw allow in on eth1 proto tcp to any port 3129 # HTTP redirect to HTTPS
#lxc exec $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME -- ufw allow in on eth1 proto tcp to any port 3130 # HTTPS
#lxc exec $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME -- ufw allow in on eth1 proto tcp to any port 80 # 80 for Docker Private REgistry
lxc exec $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME -- ufw allow in on eth1 proto tcp to any port 5000 # 5000 for docker registry pull through cache.
lxc exec $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME -- ufw allow in on eth1 proto tcp to any port 53 #DNS
lxc exec $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME -- ufw allow in on eth1 proto udp to any port 53 #DNS
lxc exec $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME -- ufw allow in on eth1 proto udp to any port 67 #DHCP
#lxc exec $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME -- ufw allow in on eth1 proto udp to any port 69 #TFTP
lxc exec $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME -- ufw enable


lxc stop $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME

sleep 2

lxc snapshot $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME bcm-gateway-snapshot






# # archived
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