#!/usr/bin/env bash

set -eu
cd "$(dirname "$0")"
source ./defaults.sh
source ../host_template/defaults.sh

# At a high level, this script works towards getting active bcm-gateway docker daemons
# running on each cluster member. The cluster master '01' is responsible for bootstrapping
# docker images to minimize network traffic. Subsequent dockerd are configured to pull
# deocker images from '01'.  '02' also hosts a docker mirror for local redundancy, but it 
# pulls from 01. So if there's an issue with 01, we can't do updates. 02 can still service
# existing images to other dockerd instances.

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

lxc exec $LXD_CONTAINER_NAME -- ifmetric eth0 50
lxc exec $LXD_CONTAINER_NAME -- docker pull registry:latest
lxc exec $LXD_CONTAINER_NAME -- docker tag registry:latest bcm-registry:latest

lxc file push daemon1.json $LXD_CONTAINER_NAME/etc/docker/daemon.json

lxc file push ./gw_docker_stack/ $LXD_CONTAINER_NAME/root/stacks/ -p -r

lxc exec $LXD_CONTAINER_NAME -- docker swarm init --advertise-addr eth1 >> /dev/null

lxc restart $LXD_CONTAINER_NAME

../shared/wait_for_dockerd.sh --container-name="$LXD_CONTAINER_NAME"

lxc exec $LXD_CONTAINER_NAME -- ifmetric eth0 50
lxc exec $LXD_CONTAINER_NAME -- env DOCKER_IMAGE="bcm-registry:latest" TARGET_PORT=5000 TARGET_HOST=$LXD_CONTAINER_NAME docker stack deploy -c /root/stacks/gw_docker_stack/registry_mirror.yml regmirror
lxc exec $LXD_CONTAINER_NAME -- env DOCKER_IMAGE="bcm-registry:latest" TARGET_PORT=5010 TARGET_HOST=$LXD_CONTAINER_NAME docker stack deploy -c /root/stacks/gw_docker_stack/private_registry.yml privateregistry

lxc exec $LXD_CONTAINER_NAME -- wait-for-it -t 0 $LXD_CONTAINER_NAME:5000
lxc exec $LXD_CONTAINER_NAME -- wait-for-it -t 0 $LXD_CONTAINER_NAME:5010

sleep 3

# first let's push the local registry image in our dockerd to the registry cache
# so other nodes can dowload it.
PRIVATE_REGISTRY="bcm-gateway-01:5010"

lxc exec $LXD_CONTAINER_NAME -- docker tag registry:latest $PRIVATE_REGISTRY/bcm-registry:latest
lxc exec $LXD_CONTAINER_NAME -- docker push $PRIVATE_REGISTRY/bcm-registry:latest


# now let's build some custom images that we're going run on each bcm-gateway
# namely TOR
export BCM_DOCKER_BASE_IMAGE="ubuntu:cosmic"

lxc exec $LXD_CONTAINER_NAME -- docker pull $BCM_DOCKER_BASE_IMAGE
lxc exec $LXD_CONTAINER_NAME -- docker tag $BCM_DOCKER_BASE_IMAGE $PRIVATE_REGISTRY/bcm-bionic-base:latest
lxc exec $LXD_CONTAINER_NAME -- docker push $PRIVATE_REGISTRY/bcm-bionic-base:latest
lxc file push ./bcm-base.Dockerfile $LXD_CONTAINER_NAME/root/Dockerfile
lxc exec $LXD_CONTAINER_NAME -- docker build -t $PRIVATE_REGISTRY/bcm-base:latest .

lxc exec $LXD_CONTAINER_NAME -- mkdir -p /root/stacks/tor
lxc file push ./tor/bcm-tor.Dockerfile $LXD_CONTAINER_NAME/root/stacks/tor/Dockerfile

TOR_IMAGE="$PRIVATE_REGISTRY/bcm-tor:latest"
lxc exec $LXD_CONTAINER_NAME -- docker build -t $TOR_IMAGE /root/stacks/tor/
lxc exec $LXD_CONTAINER_NAME -- docker push $TOR_IMAGE
lxc exec $LXD_CONTAINER_NAME -- env DOCKER_IMAGE="$TOR_IMAGE" docker stack deploy -c /root/stacks/gw_docker_stack/tor_socks5_dns.yml torsocksdns

# let's cycle through the other cluster members (other than the master)
# and get their bcm-gateway host going.


DOCKER_SWARM_MANAGER_JOIN_TOKEN=$(lxc exec bcm-gateway-01 -- docker swarm join-token manager | grep token | awk '{ print $5 }')
DOCKER_SWARM_WORKER_JOIN_TOKEN=$(lxc exec bcm-gateway-01 -- docker swarm join-token worker | grep token | awk '{ print $5 }')

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
            lxc exec $LXD_CONTAINER_NAME -- wait-for-it -t 0 bcm-gateway-01:5010
            
            # we will stop at 3 manager hosts; should be adequate.
            if [[ $HOST_ENDING -le 3 ]]; then
                lxc exec $LXD_CONTAINER_NAME -- docker swarm join --token $DOCKER_SWARM_MANAGER_JOIN_TOKEN bcm-gateway-01:2377
            else
                # All other LXD bcm-gateway-04 or greater will be workers in the swarm.
                
                lxc exec $LXD_CONTAINER_NAME -- docker swarm join --token $DOCKER_SWARM_WORKER_JOIN_TOKEN bcm-gateway-01:2377
            fi

            # only do this if we're on our second node. We're going to deploy
            # another registry mirror and private registry in case node1 goes offline.
            # We will only have 2 locations for docker image distribution.
            if [[ $HOST_ENDING = 2 ]]; then
                lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$PRIVATE_REGISTRY/bcm-registry:latest" TARGET_PORT=5001 TARGET_HOST=$LXD_CONTAINER_NAME REGISTRY_PROXY_REMOTEURL="http://bcm-gateway-01:5000" docker stack deploy -c /root/stacks/gw_docker_stack/registry_mirror.yml regmirror2
                lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$PRIVATE_REGISTRY/bcm-registry:latest" TARGET_PORT=5011 TARGET_HOST=$LXD_CONTAINER_NAME docker stack deploy -c /root/stacks/gw_docker_stack/private_registry.yml privateregistry2
            fi
        fi
    fi
done
