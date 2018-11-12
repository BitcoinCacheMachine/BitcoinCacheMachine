#!/usr/bin/env bash

set -eu
cd "$(dirname "$0")"
source ../host_template/defaults.sh
source ./defaults.sh

# if bcm-template lxc image exists, run the gateway template creation script.
if [[ -z $(lxc image list | grep "bcm-template") ]]; then
    echo "Required LXC image 'bcm-template' does not exist! Ensure your current LXD remote $(lxc remote get-default) creates or downloads a remote 'bcm-template'."
    exit
fi

./create_lxc_gateway_networks.sh

# create the 'bcm-gateway-profile' lxc profile
if [[ $BCM_GATEWAY_PROFILE_GATEWAYPROFILE_CREATE = 1 ]]; then
    if [[ -z $(lxc profile list | grep "bcm-gateway-profile") ]]; then
        lxc profile create bcm-gateway-profile
    fi

    cat ./gateway_lxd_profile.yml | lxc profile edit bcm-gateway-profile
fi

# let's make sure we have the dockertemplate to init from.
if [[ -z $(lxc list | grep "$BCM_HOSTTEMPLATE_NAME") ]]; then
    echo "Error. LXC host '$BCM_HOSTTEMPLATE_NAME' doesn't exist."
    exit
fi

# We'll quit if the host is already there.
if [[ ! -z $(lxc list | grep "$BCM_GW_TEMPLATE_NAME") ]]; then
    echo "Error. LXC host '$BCM_GW_TEMPLATE_NAME' doesn't exist."
    exit
fi

# let's init the gateway; Let's make sure it deploys to the first node so we know
# where the snapshot data is going to be made.
lxc init --target "$(lxc remote get-default)-00" $(lxc remote get-default):bcm-template $BCM_LXC_GATEWAY_CONTAINER_NAME -p bcm_default -p docker_privileged -p bcm-gateway-profile
lxc file push 10-lxc.yaml $BCM_LXC_GATEWAY_CONTAINER_NAME/etc/netplan/10-lxc.yaml
#lxc storage volume create bcm_zfs $BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME  block.filesystem=ext4

#MASTER_NODE=$(lxc info | grep server_name | xargs | awk 'NF>1{print $NF}')
#lxc storage volume attach bcm_zfs $BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME $BCM_LXC_GATEWAY_CONTAINER_NAME dockerdisk path=/var/lib/docker

lxc start $BCM_LXC_GATEWAY_CONTAINER_NAME

../shared/wait_for_dockerd.sh --container-name="$BCM_LXC_GATEWAY_CONTAINER_NAME"

lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker swarm init --advertise-addr 127.0.0.1 >> /dev/null

export BCM_DOCKER_BASE_IMAGE="ubuntu:bionic-20181018"

lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker pull $BCM_DOCKER_BASE_IMAGE
lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker tag $BCM_DOCKER_BASE_IMAGE bcm-bionic-base:latest
lxc file push ./dockerfiles/bcm-base.Dockerfile $BCM_LXC_GATEWAY_CONTAINER_NAME/root/Dockerfile
lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker build -t bcm-base:latest .


lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- mkdir -p /root/docker/tor
lxc file push ./dockerfiles/tor/bcm-tor.Dockerfile $BCM_LXC_GATEWAY_CONTAINER_NAME/root/docker/tor/Dockerfile
lxc file push ./dockerfiles/tor/torrc $BCM_LXC_GATEWAY_CONTAINER_NAME/root/docker/tor/torrc
lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker build -t bcm-tor:latest /root/docker/tor/


# lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- mkdir -p /root/docker/dnsmasq
# lxc file push ./dockerfiles/dnsmasq/dnsmasq.Dockerfile $BCM_LXC_GATEWAY_CONTAINER_NAME/root/docker/dnsmasq/Dockerfile
# lxc file push ./dockerfiles/dnsmasq/dnsmasq.conf $BCM_LXC_GATEWAY_CONTAINER_NAME/root/docker/dnsmasq/dnsmasq.conf
# lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker build -t bcm-dnsmasq:latest /root/docker/dnsmasq/

lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker pull consul:1.4.0-rc1
lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker tag consul:1.4.0-rc1 bcm-consul:latest

lxc stop $BCM_LXC_GATEWAY_CONTAINER_NAME

lxc snapshot $BCM_LXC_GATEWAY_CONTAINER_NAME bcm-gateway-template

lxc publish $BCM_LXC_GATEWAY_CONTAINER_NAME/bcm-gateway-template $(lxc remote get-default): --alias bcm-gateway-template 
#--public

lxc delete bcm-gateway

# let's get a bcm-gateway LXC instance on each cluster endpoint.
for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
    HOST_ENDING=$(echo $endpoint | tail -c 2)
    LXD_CONTAINER_NAME=bcm-gateway-$(printf %02d $HOST_ENDING)
    lxc init --target $endpoint bcm-gateway-template $LXD_CONTAINER_NAME -p bcm_default -p docker_privileged -p bcm-gateway-profile
    lxc start $LXD_CONTAINER_NAME
done








# for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
#     #lxc file push daemon.json $BCM_LXC_GATEWAY_CONTAINER_NAME/etc/docker/daemon.json
#     echo "Running LXC STORAGE VOLUME CREATE on $endpoint"
    
# done

######### RUNTIME
#lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker run -d --name=dev-consul --net=host -e CONSUL_BIND_INTERFACE=eth1 bcm-consul:latest


# # disable systemd-resolved so don't have a conflict on port 53 when dnsmasq binds.
# lxc file push resolved.conf $BCM_LXC_GATEWAY_CONTAINER_NAME/etc/systemd/resolved.conf
# lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- chown root:root /etc/systemd/resolved.conf
# lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- chmod 0644 /etc/systemd/resolved.conf

# lxc restart $BCM_LXC_GATEWAY_CONTAINER_NAME

# ../shared/wait_for_dockerd.sh --container-name="$BCM_LXC_GATEWAY_CONTAINER_NAME"


# lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker run --name tor -d --restart always bcm-tor:latest
# lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker exec -t tor wait-for-it -t 0 127.0.15.1:9050

# lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker run --name dnsmasq -d --restart always --net=host --cap-add=NET_ADMIN bcm-dnsmasq:latest

# # now let's update gateway's dockerd daemon to use the mirror it itself is hosting.
# lxc file push finished.daemon.json $BCM_LXC_GATEWAY_CONTAINER_NAME/etc/docker/daemon.json

# lxc restart $BCM_LXC_GATEWAY_CONTAINER_NAME

# ../lxd/shared/wait_for_dockerd.sh --container-name="$BCM_LXC_GATEWAY_CONTAINER_NAME"

# bash -c ./stacks/up_lxc_gateway_stacks.sh






#lxc storage volume detach bcm_zfs $BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME $BCM_LXC_GATEWAY_CONTAINER_NAME dockerdisk

#lxc storage volume snapshot bcm_zfs $BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME gateway-baseline
