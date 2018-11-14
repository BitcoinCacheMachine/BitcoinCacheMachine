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

# create the 'bcm_gateway_profile' lxc profile
if [[ $BCM_GATEWAY_PROFILE_GATEWAYPROFILE_CREATE = 1 ]]; then
    if [[ -z $(lxc profile list | grep "bcm_gateway_profile") ]]; then
        lxc profile create bcm_gateway_profile
    fi

    cat ./gateway_lxd_profile.yml | lxc profile edit bcm_gateway_profile
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

# let's get a bcm-gateway LXC instance on each cluster endpoint.
MASTER_NODE=$(lxc info | grep server_name | xargs | awk 'NF>1{print $NF}')
for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
    HOST_ENDING=$(echo $endpoint | tail -c 2)
    LXD_CONTAINER_NAME="bcm-gateway-$(printf %02d $HOST_ENDING)"
    DOCKERVOL="$LXD_CONTAINER_NAME-dockerdisk"
    
    echo "HOST_ENDING: $HOST_ENDING"
    echo "Creating volume '$DOCKERVOL' on storage pool bcm_btrfs on cluster member '$endpoint'."
    if [ $endpoint != $MASTER_NODE ]; then
        lxc storage volume create bcm_btrfs $DOCKERVOL block.filesystem=ext4 --target $endpoint
    else
        lxc storage volume create bcm_btrfs $DOCKERVOL block.filesystem=ext4
    fi
    
    lxc init --target $endpoint bcm-template $LXD_CONTAINER_NAME --profile=bcm_default --profile=docker_privileged -p bcm_gateway_profile

    lxc storage volume attach bcm_btrfs $DOCKERVOL $LXD_CONTAINER_NAME dockerdisk path=/var/lib/docker

    lxc file push ./gateway_ip_addr_template.yml $LXD_CONTAINER_NAME/etc/netplan/10-lxc.yaml
done

# let's start the LXD container on the LXD cluster master.
LXD_CONTAINER_NAME="bcm-gateway-01"
lxc start $LXD_CONTAINER_NAME

../shared/wait_for_dockerd.sh --container-name="$LXD_CONTAINER_NAME"

lxc exec $LXD_CONTAINER_NAME -- docker pull registry:latest

lxc file push daemon1.json $LXD_CONTAINER_NAME/etc/docker/daemon.json

lxc file push ./stacks/registry_mirror/ $LXD_CONTAINER_NAME/root/stacks/ -p -r
lxc file push ./stacks/private_registry/ $LXD_CONTAINER_NAME/root/stacks/ -p -r

lxc exec $LXD_CONTAINER_NAME -- docker swarm init --advertise-addr eth1 >> /dev/null

lxc restart $LXD_CONTAINER_NAME

../shared/wait_for_dockerd.sh --container-name="$LXD_CONTAINER_NAME"

DOCKER_SWARM_MANAGER_JOIN_TOKEN=$(lxc exec $LXD_CONTAINER_NAME -- docker swarm join-token manager | grep token | awk '{ print $5 }')
DOCKER_SWARM_WORKER_JOIN_TOKEN=$(lxc exec $LXD_CONTAINER_NAME -- docker swarm join-token worker | grep token | awk '{ print $5 }')

lxc exec $LXD_CONTAINER_NAME -- env TARGET_HOST=$LXD_CONTAINER_NAME docker stack deploy -c /root/stacks/registry_mirror/registry_mirror.yml regmirror
lxc exec $LXD_CONTAINER_NAME -- env TARGET_HOST=$LXD_CONTAINER_NAME docker stack deploy -c /root/stacks/private_registry/private_registry.yml privateregistry

lxc exec $LXD_CONTAINER_NAME -- wait-for-it -t 0 $LXD_CONTAINER_NAME:5000
lxc exec $LXD_CONTAINER_NAME -- wait-for-it -t 0 $LXD_CONTAINER_NAME:443

sleep 3

# first let's push the local registry image in our dockerd to the registry cache
# so other nodes can dowload it.
lxc exec $LXD_CONTAINER_NAME -- docker tag registry:latest bcm-gateway-01:443/bcm-registry:latest
lxc exec $LXD_CONTAINER_NAME -- docker push bcm-gateway-01:443/bcm-registry:latest


# now let's build some custom images that we're going run on each bcm-gateway
# namely TOR
export BCM_DOCKER_BASE_IMAGE="ubuntu:bionic-20181018"

lxc exec $LXD_CONTAINER_NAME -- docker pull $BCM_DOCKER_BASE_IMAGE
lxc exec $LXD_CONTAINER_NAME -- docker tag $BCM_DOCKER_BASE_IMAGE bcm-gateway-01:443/bcm-bionic-base:latest
lxc exec $LXD_CONTAINER_NAME -- docker push bcm-gateway-01:443/bcm-bionic-base:latest
lxc file push ./stacks/bcm-base.Dockerfile $LXD_CONTAINER_NAME/root/Dockerfile
lxc exec $LXD_CONTAINER_NAME -- docker build -t bcm-gateway-01:443/bcm-base:latest .

lxc exec $LXD_CONTAINER_NAME -- mkdir -p /root/stacks/tor
lxc file push ./stacks/tor/bcm-tor.Dockerfile $LXD_CONTAINER_NAME/root/stacks/tor/Dockerfile
lxc file push ./stacks/tor/tor_socks5_dns.yml $LXD_CONTAINER_NAME/root/stacks/tor/tor_socks5_dns.yml
lxc file push ./stacks/tor/torrc $LXD_CONTAINER_NAME/root/stacks/tor/torrc

lxc exec $LXD_CONTAINER_NAME -- docker build -t bcm-gateway-01:443/bcm-tor:latest /root/stacks/tor/
lxc exec $LXD_CONTAINER_NAME -- docker push bcm-gateway-01:443/bcm-tor:latest
lxc exec $LXD_CONTAINER_NAME -- docker stack deploy -c /root/stacks/tor/tor_socks5_dns.yml gwtor



# let's cycle through the other cluster members (other than the master)
# and get their bcm-gateway host going.
for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
    if [[ $endpoint != $MASTER_NODE ]]; then
        HOST_ENDING=$(echo $endpoint | tail -c 2)
        LXD_CONTAINER_NAME="bcm-gateway-$(printf %02d $HOST_ENDING)"

        if [[ $HOST_ENDING -ge 2 ]]; then
            lxc file push member.daemon.json $LXD_CONTAINER_NAME/etc/docker/daemon.json

            lxc start $LXD_CONTAINER_NAME

            ../shared/wait_for_dockerd.sh --container-name="$LXD_CONTAINER_NAME"

            lxc exec $LXD_CONTAINER_NAME -- wait-for-it -t 0 bcm-gateway-01:2377
            lxc exec $LXD_CONTAINER_NAME -- wait-for-it -t 0 bcm-gateway-01:5000
            lxc exec $LXD_CONTAINER_NAME -- wait-for-it -t 0 bcm-gateway-01:443
            
            lxc exec $LXD_CONTAINER_NAME -- docker swarm join --token $DOCKER_SWARM_MANAGER_JOIN_TOKEN bcm-gateway-01:2377 
        fi
    fi
done

















# # disable systemd-resolved so don't have a conflict on port 53 when dnsmasq binds.
# lxc file push resolved.conf $BCM_LXC_GATEWAY_CONTAINER_NAME/etc/systemd/resolved.conf
# lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- chown root:root /etc/systemd/resolved.conf
# lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- chmod 0644 /etc/systemd/resolved.conf

# lxc restart $BCM_LXC_GATEWAY_CONTAINER_NAME




# lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker run --name dnsmasq -d --restart always --net=host --cap-add=NET_ADMIN bcm-dnsmasq:latest

# # now let's update gateway's dockerd daemon to use the mirror it itself is hosting.
# lxc file push finished.daemon.json $BCM_LXC_GATEWAY_CONTAINER_NAME/etc/docker/daemon.json

# lxc restart $BCM_LXC_GATEWAY_CONTAINER_NAME

# ../lxd/shared/wait_for_dockerd.sh --container-name="$BCM_LXC_GATEWAY_CONTAINER_NAME"

# bash -c ./stacks/up_lxc_gateway_stacks.sh

