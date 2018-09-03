#!/bin/bash
# exit script if there's an error anywhere
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# call bcm_script_before.sh to perform the things that every BCM script must do prior to proceeding
bash -c $BCM_LOCAL_GIT_REPO/resources/bcm/bcm_script_before.sh

# if bcm-template lxc image exists, run the rest of the script.
if [[ -z $(lxc image list | grep "bcm-template") ]]; then
    echo "Required LXC image 'bcm-template' does not exist! Ensure your current LXD remote $(lxc remote get-default) creates or downloads a remote 'bcm-template-cachestack'."
    exit 1
fi

# # create and populate the required networks
# bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/create_lxc_network_bridge_nat.sh $BCM_CACHESTACK_NETWORK_LXDBRGATEWAY_CREATE lxdbrCachestack"

# create an bcm-gateway-profile
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/create_lxc_profile.sh $BCM_CACHESTACK_PROFILE_CACHESTACK_PROFILE_CREATE bcm-cachestack-profile $BCM_LOCAL_GIT_REPO/lxd/cachestack/cachestack_lxc_profile.yml"


#### this is what we do when we are told to attach an underlay, ie when gateway is on a separate
# network device.
if [[ $BCM_CACHESTACK_MACVLAN_TO_UNDERLAY = "true" ]]; then
    # then update the profile with the user-specified interface
    echo "Setting lxc profile 'bcm-cachestack-profile' eth0 to host interface '$BCM_CACHESTACK_MACVLAN_INTERFACE'."
    lxc profile device set bcm-cachestack-profile eth0 type nic
    lxc profile device set bcm-cachestack-profile eth0 nictype macvlan
    lxc profile device set bcm-cachestack-profile eth0 parent $BCM_CACHESTACK_MACVLAN_INTERFACE
else
    echo "BCM directed to perform a standalone deployment. LXC container '$BCM_LXC_CACHESTACK_CONTAINER_TEMPLATE_NAME' will not MACVLAN any interface; it connects to a bcm-gateway via a LXC local network bridge."
fi


# create a cachestack template if it doesn't exist.
if [[ -z $(lxc list | grep "$BCM_LXC_CACHESTACK_CONTAINER_TEMPLATE_NAME") ]]; then
    # let's generate a LXC template to base our lxc container on.
    lxc init bcm-template $BCM_LXC_CACHESTACK_CONTAINER_TEMPLATE_NAME -p bcm_disk -p docker_privileged -p bcm-cachestack-profile
fi

lxc file push 10-lxc.yaml $BCM_LXC_CACHESTACK_CONTAINER_TEMPLATE_NAME/etc/netplan/10-lxc.yaml

echo "Starting '$BCM_LXC_CACHESTACK_CONTAINER_TEMPLATE_NAME'."
lxc start $BCM_LXC_CACHESTACK_CONTAINER_TEMPLATE_NAME

sleep 15

# we're going to update the docker daemon to use the HTTP/HTTPs proxy on gateway.
lxc exec $BCM_LXC_CACHESTACK_CONTAINER_NAME -- mkdir -p /etc/systemd/system/docker.service.d
lxc file push https-proxy.conf $BCM_LXC_CACHESTACK_CONTAINER_NAME/etc/systemd/system/docker.service.d/https-proxy.conf
lxc file push http-proxy.conf $BCM_LXC_CACHESTACK_CONTAINER_NAME/etc/systemd/system/docker.service.d/http-proxy.conf

lxc exec $BCM_LXC_CACHESTACK_CONTAINER_NAME -- mkdir -p /etc/pki/tls/certs
lxc file push ~/.bcm/runtime/$(lxc remote get-default)/bcm-gateway/bcm.tld.cert.DER $BCM_LXC_CACHESTACK_CONTAINER_NAME/etc/pki/tls/certs/ca-bundle.crt

lxc stop $BCM_LXC_CACHESTACK_CONTAINER_NAME

# create a snapshot from which all production managers will be based.
lxc snapshot $BCM_LXC_CACHESTACK_CONTAINER_NAME "BCMCachestackTemplate"
