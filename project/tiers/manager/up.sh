#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

export TIER_NAME=manager

# first, create the profile that represents the tier.
../create_tier_profile.sh --tier-name="$TIER_NAME"

# the way we provision a network on a cluster of count 1 is DIFFERENT
# than one that's larger than 1.
if [[ $CLUSTER_NODE_COUNT -gt 1 ]]; then
    # create and populate the required network
    
    # we have to do this for each cluster node
    for endpoint in $CLUSTER_ENDPOINTS; do
        lxc network create --target "$endpoint" bcmbrGWNat
        lxc network create --target "$endpoint" bcmNet
    done
fi

function createBCMBRGW() {
    if ! lxc network list --format csv | grep -q bcmbrGWNat; then
        lxc network create bcmbrGWNat ipv4.nat=true ipv6.nat=false ipv6.address=none
    fi
}

function createBCMNet() {
    if ! lxc network list --format csv | grep -q bcmNet; then
        lxc network create bcmNet bridge.mode=fan dns.mode=dynamic
        # fan.underlay_subnet=172.17.0.0/24
    fi
}

#
if lxc network list --format csv | grep bcmbrGWNat | grep -q PENDING; then
    createBCMBRGW
fi

if ! lxc network list --format csv | grep -q bcmbrGWNat; then
    createBCMBRGW
fi

#
if lxc network list --format csv | grep bcmNet | grep -q PENDING; then
    createBCMNet
fi

if ! lxc network list --format csv | grep -q bcmNet; then
    createBCMNet
fi

# get all the bcm-manager-xx containers deployed to the cluster.
../spread_lxc_hosts.sh --tier-name="manager"

# let's start the LXD container on the LXD cluster master.
lxc file push ./dhcpd_conf.yml "$BCM_MANAGER_HOST_NAME/etc/netplan/10-lxc.yaml"

if lxc list --format csv -c=ns | grep "$BCM_MANAGER_HOST_NAME" | grep -q STOPPED; then
    # start the BCM_MANAGER_HOST_NAME and wait for dockerd
    lxc start "$BCM_MANAGER_HOST_NAME"
fi

bash -c "$BCM_LXD_OPS/wait_for_dockerd.sh --container-name=$BCM_MANAGER_HOST_NAME"

# prepare the host.
lxc exec "$BCM_MANAGER_HOST_NAME" -- ifmetric eth0 50
lxc exec "$BCM_MANAGER_HOST_NAME" -- docker image pull registry:latest
lxc exec "$BCM_MANAGER_HOST_NAME" -- docker tag registry:latest bcm-registry:latest

# only do this if the swarm hasn't already been initialized.
lxc exec "$BCM_MANAGER_HOST_NAME" -- docker swarm init --advertise-addr eth1 >> /dev/null

# upload the docker daemon config to BCM_MANAGER_HOST_NAME
# TODO update this to use a tmpfs mount for temp storage.
mkdir -p "$BCM_TMP_DIR"
envsubst <./daemon1.json > "$BCM_TMP_DIR/daemon-updated.json"
lxc file push "$BCM_TMP_DIR/daemon-updated.json" "$BCM_MANAGER_HOST_NAME"/etc/docker/daemon.json
rm "$BCM_TMP_DIR/daemon-updated.json"

# restart the host so it runs with new dockerd daemon config.
lxc restart "$BCM_MANAGER_HOST_NAME"
bash -c "$BCM_LXD_OPS/wait_for_dockerd.sh --container-name=$BCM_MANAGER_HOST_NAME"

# push the stack files up tthere.
lxc file push  -p -r ./stacks/ "$BCM_MANAGER_HOST_NAME"/root/manager/

lxc exec "$BCM_MANAGER_HOST_NAME" -- env DOCKER_IMAGE="bcm-registry:latest" \
TARGET_PORT="$BCM_REGISTRY_MIRROR_PORT" \
TARGET_HOST="$BCM_MANAGER_HOST_NAME" \
REGISTRY_PROXY_REMOTEURL="https://$BCM_DOCKER_IMAGE_CACHE_FQDN" \
docker stack deploy -c "/root/$TIER_NAME/stacks/registry/regmirror.yml" regmirror

lxc exec "$BCM_MANAGER_HOST_NAME" -- wait-for-it -t 30 "$BCM_MANAGER_HOST_NAME:$BCM_REGISTRY_MIRROR_PORT"

lxc exec "$BCM_MANAGER_HOST_NAME" -- env DOCKER_IMAGE="bcm-registry:latest" \
TARGET_PORT="$BCM_PRIVATE_REGISTRY_PORT" \
TARGET_HOST="$BCM_MANAGER_HOST_NAME" \
docker stack deploy -c "/root/manager/stacks/registry/privreg.yml" privateregistry

lxc exec "$BCM_MANAGER_HOST_NAME" -- wait-for-it -t 30 "$BCM_MANAGER_HOST_NAME:$BCM_PRIVATE_REGISTRY_PORT"

# tag and push the registry image to our local private registry.
lxc exec "$BCM_MANAGER_HOST_NAME" -- docker tag registry:latest "$BCM_PRIVATE_REGISTRY/bcm-registry:latest"
lxc exec "$BCM_MANAGER_HOST_NAME" -- docker push "$BCM_PRIVATE_REGISTRY/bcm-registry:latest"

# build and push the docker-base docker image.
IMAGE_NAME="bcm-docker-base"
lxc file push -p -r ./build/ "$BCM_MANAGER_HOST_NAME"/root/manager/
IMAGE_NAME="$BCM_PRIVATE_REGISTRY/$IMAGE_NAME:$BCM_VERSION"
lxc exec "$BCM_MANAGER_HOST_NAME" -- docker image pull "$BASE_DOCKER_IMAGE"
lxc exec "$BCM_MANAGER_HOST_NAME" -- docker build --build-arg BASE_IMAGE="$BASE_DOCKER_IMAGE" -t "$IMAGE_NAME" /root/manager/build/
lxc exec "$BCM_MANAGER_HOST_NAME" -- docker push "$IMAGE_NAME"


# let's cycle through the other cluster members (other than the master)
# and get their bcm-manager host going.
# shellcheck disable=SC1090
source "$BCM_GIT_DIR/project/tiers/get_docker_swarm_tokens.sh"

## TODO this probably doesn't work with multiple manager containers at the moment.
# todo need to update daemon.json to populate with hostname of manager-01
MASTER_NODE=$(echo "$CLUSTER_ENDPOINTS" | grep '01')
HOSTNAME=
for ENDPOINT in $CLUSTER_ENDPOINTS; do
    if [[ $ENDPOINT != "$MASTER_NODE" ]]; then
        HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
        HOSTNAME="bcm-manager-$(printf %02d "$HOST_ENDING")"
        
        if [[ $HOST_ENDING -ge 2 ]]; then
            lxc file push ./daemon.json "$HOSTNAME/etc/docker/daemon.json"
            lxc file push ./dhcpd_conf.yml "$HOSTNAME/etc/netplan/10-lxc.yaml"
            
            lxc start "$HOSTNAME"
            
            bash -c "$BCM_LXD_OPS/wait_for_dockerd.sh --container-name=$HOSTNAME"
            
            # make sure manager and kafka hosts can reach the swarm master.
            # this steps helps resolve networking before we issue any meaningful
            # commands.
            lxc exec "$LXC_HOSTNAME" -- wait-for-it -t 10 -q "$BCM_MANAGER_HOST_NAME":2377
            lxc exec "$LXC_HOSTNAME" -- wait-for-it -t 10 -q "$BCM_MANAGER_HOST_NAME:$BCM_REGISTRY_MIRROR_PORT"
            lxc exec "$LXC_HOSTNAME" -- wait-for-it -t 10 "$BCM_PRIVATE_REGISTRY"
            
            if [[ $HOST_ENDING -le 3 ]]; then
                lxc exec "$LXC_HOSTNAME" -- docker swarm join --token "$DOCKER_SWARM_MANAGER_JOIN_TOKEN" "$BCM_MANAGER_HOST_NAME":2377
            else
                # All other LXD bcm-manager-04 or greater will be workers in the swarm.
                lxc exec "$LXC_HOSTNAME" -- docker swarm join --token "$DOCKER_SWARM_WORKER_JOIN_TOKEN" "$BCM_MANAGER_HOST_NAME":2377
            fi
            
            # only do this if we're on our second node. We're going to deploy
            # another registry mirror and private registry in case node1 goes offline.
            # We will only have 2 locations for docker image distribution.
            if [[ $HOST_ENDING == 2 ]]; then
                lxc exec "$LXC_HOSTNAME" -- env DOCKER_IMAGE="$BCM_PRIVATE_REGISTRY/bcm-registry:$BCM_VERSION" TARGET_PORT=5001 TARGET_HOST="$HOSTNAME" REGISTRY_PROXY_REMOTEURL="http://bcm-manager-01:$BCM_REGISTRY_MIRROR_PORT" docker stack deploy -c "/root/manager/stacks/registry/regmirror.yml" regmirror2
            fi
        fi
    fi
done

# if we're in debug mode, some visual UIs will be deployed for kafka inspection
if [[ $BCM_DEBUG == 1 ]]; then
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/portainer/env --container-name=$BCM_MANAGER_HOST_NAME"
fi