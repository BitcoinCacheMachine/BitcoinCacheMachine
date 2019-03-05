#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# ensure basic needs are met.
bash -c "$BCM_GIT_DIR/project/up.sh"

# shellcheck disable=SC1091
source ./env

# first, create the profile that represents the tier.
bash -c "$BCM_LXD_OPS/create_tier_profile.sh --tier-name=gateway --yaml-path=$(pwd)/tier_profile.yml"

# create the networks for the gateway tier.
bash -c "./create_lxc_gateway_networks.sh"

# get all the bcm-gateway-xx containers deployed to the cluster.
bash -c "$BCM_LXD_OPS/spread_lxc_hosts.sh --tier-name=gateway"

# let's start the LXD container on the LXD cluster master.
lxc file push ./dhcpd_conf.yml bcm-gateway-01/etc/netplan/10-lxc.yaml

if lxc list --format csv -c=ns | grep bcm-gateway-01 | grep -q STOPPED; then
    # start the LXC host and wait for dockerd
    lxc start bcm-gateway-01
fi

bash -c "$BCM_GIT_DIR/project/shared/wait_for_dockerd.sh --container-name=bcm-gateway-01"

# prepare the host.
lxc exec bcm-gateway-01 -- ifmetric eth0 50
lxc exec bcm-gateway-01 -- docker pull registry:latest
lxc exec bcm-gateway-01 -- docker tag registry:latest bcm-registry:latest

# only do this if the swarm hasn't already been initialized.
if lxc exec bcm-gateway-01 -- docker info | grep "Swarm: " | grep -q "inactive"; then
    lxc exec bcm-gateway-01 -- docker swarm init --advertise-addr eth1 >> /dev/null
fi

lxc file push ./bcm-gateway-01.daemon.json bcm-gateway-01/etc/docker/daemon.json

# restart the host so it runs with new dockerd daemon config.
lxc restart bcm-gateway-01
bash -c "$BCM_GIT_DIR/project/shared/wait_for_dockerd.sh --container-name=bcm-gateway-01"


# TODO - make static
# update the route metric of the gateway host so it prefers eth0 which is lxd network bcmGWNat
REGISTRY_PROXY_REMOTEURL="https://registry-1.docker.io"
if [[ ! -z ${DOCKER_IMAGE_CACHE+x} ]]; then
    REGISTRY_PROXY_REMOTEURL="http://$DOCKER_IMAGE_CACHE:5000"
fi

# push the stack files up tthere.
lxc file push  -p -r ./stacks/ bcm-gateway-01/root/gateway/

lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="bcm-registry:latest" TARGET_PORT=5000 TARGET_HOST="bcm-gateway-01" REGISTRY_PROXY_REMOTEURL="$REGISTRY_PROXY_REMOTEURL" docker stack deploy -c "/root/$BCM_TIER_NAME/stacks/registry/regmirror.yml" regmirror
lxc exec bcm-gateway-01 -- wait-for-it -t 0 "bcm-gateway-01:5000"

lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="bcm-registry:latest" TARGET_PORT=5010 TARGET_HOST="bcm-gateway-01" docker stack deploy -c "/root/gateway/stacks/registry/privreg.yml" privreg
lxc exec bcm-gateway-01 -- wait-for-it -t 0 "bcm-gateway-01:5010"

# tag and push the registry image to our local private registry.
lxc exec bcm-gateway-01 -- docker tag registry:latest "$BCM_PRIVATE_REGISTRY/bcm-registry:latest"
lxc exec bcm-gateway-01 -- docker push "$BCM_PRIVATE_REGISTRY/bcm-registry:latest"

# now let's build some custom images that we're going run on each bcm-gateway
# namely TOR
lxc exec bcm-gateway-01 -- docker pull ubuntu:latest

lxc file push -p -r ./build/ bcm-gateway-01/root/gateway/

lxc exec bcm-gateway-01 -- docker build -t "$BCM_PRIVATE_REGISTRY/bcm-docker-base:latest" /root/gateway/build/
lxc exec bcm-gateway-01 -- docker push "$BCM_PRIVATE_REGISTRY/bcm-docker-base:latest"

TOR_IMAGE="$BCM_PRIVATE_REGISTRY/bcm-tor:latest"
lxc exec bcm-gateway-01 -- docker build -t "$TOR_IMAGE" "/root/gateway/build/tor/"
lxc exec bcm-gateway-01 -- docker push "$TOR_IMAGE"
lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$TOR_IMAGE" docker stack deploy -c "/root/gateway/stacks/tor/torstack.yml" torstack

# let's cycle through the other cluster members (other than the master)
# and get their bcm-gateway host going.
# shellcheck disable=SC1090
source "$BCM_LXD_OPS/get_docker_swarm_tokens.sh"

MASTER_NODE=$(bcm cluster list --endpoints | grep '01')
HOSTNAME=
for ENDPOINT in $(bcm cluster list --endpoints); do
    if [[ $ENDPOINT != "$MASTER_NODE" ]]; then
        HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
        HOSTNAME="bcm-gateway-$(printf %02d "$HOST_ENDING")"
        
        if [[ $HOST_ENDING -ge 2 ]]; then
            lxc file push ./daemon.json "$HOSTNAME/etc/docker/daemon.json"
            lxc file push ./dhcpd_conf.yml "$HOSTNAME/etc/netplan/10-lxc.yaml"
            
            lxc start "$HOSTNAME"
            
            bash -c "$BCM_GIT_DIR/project/shared/wait_for_dockerd.sh --container-name=$HOSTNAME"
            
            # make sure gateway and kafka hosts can reach the swarm master.
            # this steps helps resolve networking before we issue any meaningful
            # commands.
            lxc exec "$HOSTNAME" -- wait-for-it -t 0 -q bcm-gateway-01:2377
            lxc exec "$HOSTNAME" -- wait-for-it -t 0 -q bcm-gateway-01:5000
            lxc exec "$HOSTNAME" -- wait-for-it -t 0 "$BCM_PRIVATE_REGISTRY"
            
            if [[ $HOST_ENDING -le 3 ]]; then
                lxc exec "$HOSTNAME" -- docker swarm join --token "$DOCKER_SWARM_MANAGER_JOIN_TOKEN" bcm-gateway-01:2377
            else
                # All other LXD bcm-gateway-04 or greater will be workers in the swarm.
                lxc exec "$HOSTNAME" -- docker swarm join --token "$DOCKER_SWARM_WORKER_JOIN_TOKEN" bcm-gateway-01:2377
            fi
            
            # only do this if we're on our second node. We're going to deploy
            # another registry mirror and private registry in case node1 goes offline.
            # We will only have 2 locations for docker image distribution.
            if [[ $HOST_ENDING == 2 ]]; then
                lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$BCM_PRIVATE_REGISTRY/bcm-registry:latest" TARGET_PORT=5001 TARGET_HOST="bcm-gateway-01" REGISTRY_PROXY_REMOTEURL="http://$BCM_PRIVATE_REGISTRY" docker stack deploy -c "/root/gateway/stacks/registry/regmirror.yml" regmirror2
            fi
        fi
    fi
done