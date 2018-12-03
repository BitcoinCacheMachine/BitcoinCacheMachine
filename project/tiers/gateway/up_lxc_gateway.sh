#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1091
source ./.env

# first let's check to see if we have any gateways
# if so, we quit unless the user has told us to override.
export HOSTNAME="bcm-$BCM_TIER_NAME-01"
if lxc list --format csv -c n | grep -q "$HOSTNAME"; then
    echo "lxc host '$HOSTNAME' exists."
    exit
fi

# first, create the profile that represents the tier.
bash -c "$BCM_LXD_OPS/create_tier_profile.sh --tier-name=$BCM_TIER_NAME --yaml-path=$(readlink -f ./tier_profile.yml)"

bash -c "./create_lxc_gateway_networks.sh"

# get all the bcm-gateway-xx containers deployed to the cluster.
bash -c "$BCM_LXD_OPS/spread_lxc_hosts.sh --tier-name=gateway"

# let's start the LXD container on the LXD cluster master.
lxc file push ./dhcpd_conf.yml "$HOSTNAME/etc/netplan/10-lxc.yaml"

lxc start "$HOSTNAME"

# let's configure the bcm-gateway-01 first since it is the first member
# of the docker swarm.
bash -c "$BCM_GIT_DIR/project/shared/wait_for_dockerd.sh --container-name=$HOSTNAME"

lxc exec "$HOSTNAME" -- ifmetric eth0 50
lxc exec "$HOSTNAME" -- docker pull registry:latest
lxc exec "$HOSTNAME" -- docker tag registry:latest bcm-registry:latest

lxc file push ./registry/ "$HOSTNAME/root/stacks/$BCM_TIER_NAME/" -p -r

lxc exec "$HOSTNAME" -- docker swarm init --advertise-addr eth1 >> /dev/null

lxc file push "./$HOSTNAME.daemon.json" "$HOSTNAME/etc/docker/daemon.json"

lxc restart "$HOSTNAME"
bash -c "$BCM_GIT_DIR/project/shared/wait_for_dockerd.sh --container-name=$HOSTNAME"


# TODO - make static 
# update the route metric of the gateway host so it prefers eth0 which is lxd network bcmGWNat
lxc exec "$HOSTNAME" -- env DOCKER_IMAGE="bcm-registry:latest" TARGET_PORT=5000 TARGET_HOST="$HOSTNAME" docker stack deploy -c "/root/stacks/$BCM_TIER_NAME/registry/regmirror.yml" regmirror
lxc exec "$HOSTNAME" -- env DOCKER_IMAGE="bcm-registry:latest" TARGET_PORT=5010 TARGET_HOST="$HOSTNAME" docker stack deploy -c "/root/stacks/$BCM_TIER_NAME/registry/privreg.yml" privreg

lxc exec "$HOSTNAME" -- wait-for-it -t 0 "$HOSTNAME:5000"
lxc exec "$HOSTNAME" -- wait-for-it -t 0 "$HOSTNAME:5010"

lxc exec "$HOSTNAME" -- docker tag registry:latest "$BCM_PRIVATE_REGISTRY/bcm-registry:latest"
lxc exec "$HOSTNAME" -- docker push "$BCM_PRIVATE_REGISTRY/bcm-registry:latest"


# now let's build some custom images that we're going run on each bcm-gateway
# namely TOR
export BCM_DOCKER_BASE_IMAGE="ubuntu:cosmic"

lxc exec "$HOSTNAME" -- docker pull $BCM_DOCKER_BASE_IMAGE
lxc exec "$HOSTNAME" -- docker tag $BCM_DOCKER_BASE_IMAGE "$BCM_PRIVATE_REGISTRY/bcm-docker-base:latest"
lxc exec "$HOSTNAME" -- docker push "$BCM_PRIVATE_REGISTRY/bcm-docker-base:latest"
lxc file push ./bcm-docker-base.Dockerfile "$HOSTNAME/root/Dockerfile"
lxc exec "$HOSTNAME" -- docker build -t "$BCM_PRIVATE_REGISTRY/bcm-docker-base:latest" .


lxc file push ./tor/ "$HOSTNAME/root/stacks/$BCM_TIER_NAME/" -p -r

TOR_IMAGE="$BCM_PRIVATE_REGISTRY/bcm-tor:latest"
lxc exec "$HOSTNAME" -- docker build -t "$TOR_IMAGE" "/root/stacks/$BCM_TIER_NAME/tor/"
lxc exec "$HOSTNAME" -- docker push "$TOR_IMAGE"
lxc exec "$HOSTNAME" -- env DOCKER_IMAGE="$TOR_IMAGE" docker stack deploy -c "/root/stacks/$BCM_TIER_NAME/tor/torstack.yml" torstack


# let's cycle through the other cluster members (other than the master)
# and get their bcm-gateway host going.
# shellcheck disable=SC1090
source "$BCM_LXD_OPS/get_docker_swarm_tokens.sh"

MASTER_NODE=$(lxc info | grep server_name | xargs | awk 'NF>1{print $NF}')
for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    if [[ $endpoint != "$MASTER_NODE" ]]; then
        HOST_ENDING=$(echo "$endpoint" | tail -c 2)
        HOSTNAME="bcm-gateway-$(printf %02d "$HOST_ENDING")"

        if [[ $HOST_ENDING -ge 2 ]]; then
            lxc file push ./daemon.json "$HOSTNAME/etc/docker/daemon.json"
            lxc file push ./dhcpd_conf.yml "$HOSTNAME/etc/netplan/10-lxc.yaml"

            lxc start "$HOSTNAME"

            bash -c "$BCM_GIT_DIR/project/shared/wait_for_dockerd.sh --container-name=$HOSTNAME"

            # make sure gateway and kafka hosts can reach the swarm master.
            # this steps helps resolve networking before we issue any meaningful
            # commands.
            lxc exec "$HOSTNAME" -- wait-for-it -t 0 bcm-gateway-01:2377
            lxc exec "$HOSTNAME" -- wait-for-it -t 0 bcm-gateway-01:5000
            lxc exec "$HOSTNAME" -- wait-for-it -t 0 bcm-gateway-01:5010

            if [[ $HOST_ENDING -le 3 ]]; then
                lxc exec "$HOSTNAME" -- docker swarm join --token "$DOCKER_SWARM_MANAGER_JOIN_TOKEN" bcm-gateway-01:2377
            else
                # All other LXD bcm-gateway-04 or greater will be workers in the swarm.
                lxc exec "$HOSTNAME" -- docker swarm join --token "$DOCKER_SWARM_WORKER_JOIN_TOKEN" bcm-gateway-01:2377
            fi

            # only do this if we're on our second node. We're going to deploy
            # another registry mirror and private registry in case node1 goes offline.
            # We will only have 2 locations for docker image distribution.
            if [[ $HOST_ENDING = 2 ]]; then
                lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$BCM_PRIVATE_REGISTRY/bcm-registry:latest" TARGET_PORT=5001 TARGET_HOST="bcm-gateway-01" REGISTRY_PROXY_REMOTEURL="http://bcm-gateway-01:5010" docker stack deploy -c "/root/stacks/$BCM_TIER_NAME/registry/regmirror.yml" regmirror2
            fi
        fi
    fi
done