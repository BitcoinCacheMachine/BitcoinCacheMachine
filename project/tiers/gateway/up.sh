#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# only continue if the necessary image exists.
bash -c "$BCM_GIT_DIR/project/create_bcm_host_template.sh"

# It's at this point that we start discerning amount mainnet,testnet,regtest boundaries.
if ! lxc project list | grep -q "$BCM_PROJECT"; then
    lxc project create "$BCM_PROJECT"
    
    # these two commands means that each project will
    # inherit profiles and images contained in the default project.
    lxc project set "$BCM_PROJECT" features.images false
    lxc project set "$BCM_PROJECT" features.profiles false
fi

if ! lxc project list | grep -q "$BCM_PROJECT (current)"; then
    lxc project switch "$BCM_PROJECT"
fi

export TIER_NAME=gateway

# shellcheck source=../../project/shared/env.sh
#source "$BCM_GIT_DIR/project/shared/env.sh"

# first, create the profile that represents the tier.
bash -c "$BCM_LXD_OPS/create_tier_profile.sh --tier-name=$TIER_NAME --yaml-path=$(pwd)/tier_profile.yml"

# create the networks for the gateway tier.
bash -c "./create_lxc_gateway_networks.sh"

# get all the bcm-gateway-xx containers deployed to the cluster.
bash -c "$BCM_LXD_OPS/spread_lxc_hosts.sh --tier-name=gateway"

# let's start the LXD container on the LXD cluster master.
lxc file push ./dhcpd_conf.yml "$BCM_MANAGER_HOST_NAME/etc/netplan/10-lxc.yaml"

if lxc list --format csv -c=ns | grep "$BCM_MANAGER_HOST_NAME" | grep -q STOPPED; then
    # start the BCM_MANAGER_HOST_NAME and wait for dockerd
    lxc start "$BCM_MANAGER_HOST_NAME"
fi

bash -c "$BCM_GIT_DIR/project/shared/wait_for_dockerd.sh --container-name=$BCM_MANAGER_HOST_NAME"

# prepare the host.
lxc exec "$BCM_MANAGER_HOST_NAME" -- ifmetric eth0 50
lxc exec "$BCM_MANAGER_HOST_NAME" -- docker pull registry:latest
lxc exec "$BCM_MANAGER_HOST_NAME" -- docker tag registry:latest bcm-registry:latest

# only do this if the swarm hasn't already been initialized.
lxc exec "$BCM_MANAGER_HOST_NAME" -- docker swarm init --advertise-addr eth1 >> /dev/null

# upload the docker daemon config to BCM_MANAGER_HOST_NAME
lxc file push ./daemon1.json "$BCM_MANAGER_HOST_NAME"/etc/docker/daemon.json

# restart the host so it runs with new dockerd daemon config.
lxc restart "$BCM_MANAGER_HOST_NAME"
bash -c "$BCM_GIT_DIR/project/shared/wait_for_dockerd.sh --container-name=$BCM_MANAGER_HOST_NAME"

# push the stack files up tthere.
lxc file push  -p -r ./stacks/ "$BCM_MANAGER_HOST_NAME"/root/gateway/

lxc exec "$BCM_MANAGER_HOST_NAME" -- env DOCKER_IMAGE="bcm-registry:latest" \
TARGET_PORT=5000 \
TARGET_HOST="$BCM_MANAGER_HOST_NAME" \
REGISTRY_PROXY_REMOTEURL="https://$BCM_DOCKER_IMAGE_CACHE" \
docker stack deploy -c "/root/$TIER_NAME/stacks/registry/regmirror.yml" regmirror

lxc exec "$BCM_MANAGER_HOST_NAME" -- wait-for-it -t 30 "$BCM_MANAGER_HOST_NAME:5000"

lxc exec "$BCM_MANAGER_HOST_NAME" -- env DOCKER_IMAGE="bcm-registry:latest" \
TARGET_PORT=5010 \
TARGET_HOST="$BCM_MANAGER_HOST_NAME" \
docker stack deploy -c "/root/gateway/stacks/registry/privreg.yml" privateregistry

lxc exec "$BCM_MANAGER_HOST_NAME" -- wait-for-it -t 30 "$BCM_MANAGER_HOST_NAME:5010"

# tag and push the registry image to our local private registry.
BCM_PRIVATE_REGISTRY="127.0.0.1:5010"
lxc exec "$BCM_MANAGER_HOST_NAME" -- docker tag registry:latest "$BCM_PRIVATE_REGISTRY/bcm-registry:latest"
lxc exec "$BCM_MANAGER_HOST_NAME" -- docker push "$BCM_PRIVATE_REGISTRY/bcm-registry:latest"

# build and push the docker-base docker image.
./build_push_docker_base.sh




# let's cycle through the other cluster members (other than the master)
# and get their bcm-gateway host going.
# shellcheck disable=SC1090
source "$BCM_LXD_OPS/get_docker_swarm_tokens.sh"


## TODO this probably doesn't work with multiple gateway containers at the moment.
# todo need to update daemon.json to populate with hostname of gateway-01
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
            lxc exec "$LXC_HOSTNAME" -- wait-for-it -t 10 -q "$BCM_MANAGER_HOST_NAME":2377
            lxc exec "$LXC_HOSTNAME" -- wait-for-it -t 10 -q "$BCM_MANAGER_HOST_NAME":5000
            lxc exec "$LXC_HOSTNAME" -- wait-for-it -t 10 "$BCM_PRIVATE_REGISTRY"
            
            if [[ $HOST_ENDING -le 3 ]]; then
                lxc exec "$LXC_HOSTNAME" -- docker swarm join --token "$DOCKER_SWARM_MANAGER_JOIN_TOKEN" "$BCM_MANAGER_HOST_NAME":2377
            else
                # All other LXD bcm-gateway-04 or greater will be workers in the swarm.
                lxc exec "$LXC_HOSTNAME" -- docker swarm join --token "$DOCKER_SWARM_WORKER_JOIN_TOKEN" "$BCM_MANAGER_HOST_NAME":2377
            fi
            
            # only do this if we're on our second node. We're going to deploy
            # another registry mirror and private registry in case node1 goes offline.
            # We will only have 2 locations for docker image distribution.
            if [[ $HOST_ENDING == 2 ]]; then
                lxc exec "$LXC_HOSTNAME" -- env DOCKER_IMAGE="$BCM_PRIVATE_REGISTRY/bcm-registry:latest" TARGET_PORT=5001 TARGET_HOST="$HOSTNAME" REGISTRY_PROXY_REMOTEURL="http://bcm-gateway-01:5000" docker stack deploy -c "/root/gateway/stacks/registry/regmirror.yml" regmirror2
            fi
        fi
    fi
done

# if we're in debug mode, some visual UIs will be deployed for kafka inspection
if [[ $BCM_DEBUG == 1 ]]; then
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/portainer/env --container-name=$BCM_MANAGER_HOST_NAME"
fi