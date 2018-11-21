#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"
source ../defaults.sh
source ./defaults.sh


if [[ -z $GATEWAY_HOSTNAME ]]; then
    echo "GATEWAY_HOSTNAME not set."
    exit
fi

if [[ -z $(lxc list | grep "$GATEWAY_HOSTNAME") ]]; then
    echo "lxc host '$GATEWAY_HOSTNAME' does not exist."
    exit
fi

# let's start the LXD container on the LXD cluster master.
lxc file push ./gateway_ip_addr_template.yml $GATEWAY_HOSTNAME/etc/netplan/10-lxc.yaml

lxc start $GATEWAY_HOSTNAME

# let's configure the bcm-gateway-01 first since it is the first member
# of the docker swarm.
../../shared/wait_for_dockerd.sh --container-name="$GATEWAY_HOSTNAME"

lxc exec $GATEWAY_HOSTNAME -- ifmetric eth0 50

if [[ $GATEWAY_HOSTNAME = "bcm-gateway-01" ]]; then
    lxc exec bcm-gateway-01 -- docker pull registry:latest
    lxc exec bcm-gateway-01 -- docker tag registry:latest bcm-registry:latest

    lxc file push ./docker_stack/ bcm-gateway-01/root/stacks/ -p -r

    lxc exec bcm-gateway-01 -- docker swarm init --advertise-addr eth1 >> /dev/null

    lxc file push ./bcm-gateway-01.daemon.json $GATEWAY_HOSTNAME/etc/docker/daemon.json
    sleep 5
else
    lxc file push ./gateway.daemon.json $GATEWAY_HOSTNAME/etc/docker/daemon.json
fi

lxc restart $GATEWAY_HOSTNAME
../../shared/wait_for_dockerd.sh --container-name="$GATEWAY_HOSTNAME"

if [[ $GATEWAY_HOSTNAME = "bcm-gateway-01" ]]; then
    # TODO - make static 
    # update the route metric of the gateway host so it prefers eth0 which is lxd network bcmGWNat
    lxc exec bcm-gateway-01 -- ifmetric eth0 50
    lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="bcm-registry:latest" TARGET_PORT=5000 TARGET_HOST=bcm-gateway-01 docker stack deploy -c /root/stacks/docker_stack/registry_mirror.yml regmirror
    lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="bcm-registry:latest" TARGET_PORT=5010 TARGET_HOST=bcm-gateway-01 docker stack deploy -c /root/stacks/docker_stack/private_registry.yml privateregistry

    lxc exec bcm-gateway-01 -- wait-for-it -t 0 bcm-gateway-01:5000
    lxc exec bcm-gateway-01 -- wait-for-it -t 0 bcm-gateway-01:5010

    lxc exec bcm-gateway-01 -- docker tag registry:latest $PRIVATE_REGISTRY/bcm-registry:latest
    lxc exec bcm-gateway-01 -- docker push $PRIVATE_REGISTRY/bcm-registry:latest


    # now let's build some custom images that we're going run on each bcm-gateway
    # namely TOR
    export BCM_DOCKER_BASE_IMAGE="ubuntu:cosmic"

    lxc exec bcm-gateway-01 -- docker pull $BCM_DOCKER_BASE_IMAGE
    lxc exec bcm-gateway-01 -- docker tag $BCM_DOCKER_BASE_IMAGE $PRIVATE_REGISTRY/bcm-docker-base:latest
    lxc exec bcm-gateway-01 -- docker push $PRIVATE_REGISTRY/bcm-docker-base:latest
    lxc file push ./bcm-docker-base.Dockerfile bcm-gateway-01/root/Dockerfile
    lxc exec bcm-gateway-01 -- docker build -t $PRIVATE_REGISTRY/bcm-docker-base:latest .

    lxc exec bcm-gateway-01 -- mkdir -p /root/stacks/tor
    lxc file push ./tor/bcm-tor.Dockerfile bcm-gateway-01/root/stacks/tor/Dockerfile

    TOR_IMAGE="$PRIVATE_REGISTRY/bcm-tor:latest"
    lxc exec bcm-gateway-01 -- docker build -t $TOR_IMAGE /root/stacks/tor/
    lxc exec bcm-gateway-01 -- docker push $TOR_IMAGE
    lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$TOR_IMAGE" docker stack deploy -c /root/stacks/docker_stack/tor_socks5_dns.yml torsocksdns
fi


# let's cycle through the other cluster members (other than the master)
# and get their bcm-gateway host going.
source ../get_docker_swarm_tokens.sh
for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
    if [[ $endpoint != $MASTER_NODE ]]; then
        HOST_ENDING=$(echo $endpoint | tail -c 2)
        GATEWAY_HOSTNAME="bcm-gateway-$(printf %02d $HOST_ENDING)"

        if [[ $HOST_ENDING -ge 2 ]]; then
            lxc file push ./gateway.daemon.json $GATEWAY_HOSTNAME/etc/docker/daemon.json
            lxc file push ./gateway_ip_addr_template.yml $GATEWAY_HOSTNAME/etc/netplan/10-lxc.yaml

            lxc start $GATEWAY_HOSTNAME

            ../../shared/wait_for_dockerd.sh --container-name="$GATEWAY_HOSTNAME"

            # make sure gateway and kafka hosts can reach the swarm master.
            # this steps helps resolve networking before we issue any meaningful
            # commands.
            lxc exec $GATEWAY_HOSTNAME -- wait-for-it -t 0 bcm-gateway-01:2377
            lxc exec $GATEWAY_HOSTNAME -- wait-for-it -t 0 bcm-gateway-01:5000
            lxc exec $GATEWAY_HOSTNAME -- wait-for-it -t 0 bcm-gateway-01:5010

            if [[ $HOST_ENDING -le 3 ]]; then
                lxc exec $GATEWAY_HOSTNAME -- docker swarm join --token $DOCKER_SWARM_MANAGER_JOIN_TOKEN bcm-gateway-01:2377
            else
                # All other LXD bcm-gateway-04 or greater will be workers in the swarm.
                lxc exec $GATEWAY_HOSTNAME -- docker swarm join --token $DOCKER_SWARM_WORKER_JOIN_TOKEN bcm-gateway-01:2377
            fi

            # only do this if we're on our second node. We're going to deploy
            # another registry mirror and private registry in case node1 goes offline.
            # We will only have 2 locations for docker image distribution.
            if [[ $HOST_ENDING = 2 ]]; then
                lxc exec bcm-gateway-01 -- env DOCKER_IMAGE="$PRIVATE_REGISTRY/bcm-registry:latest" TARGET_PORT=5001 TARGET_HOST="bcm-gateway-01" REGISTRY_PROXY_REMOTEURL="http://bcm-gateway-01:5010" docker stack deploy -c /root/stacks/docker_stack/registry_mirror.yml regmirror2
            fi
        fi
    fi
done
