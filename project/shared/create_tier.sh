#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

TIER_NAME=

for i in "$@"; do
    case $i in
        --tier-name=*)
            TIER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

STACK_NAME="$TIER_NAME"
if [[ $TIER_NAME == bitcoin* ]]; then
    STACK_NAME="bitcoin"
fi

# first, create the profile that represents the tier.
bash -c "$BCM_LXD_OPS/create_tier_profile.sh --tier-name=$TIER_NAME --yaml-path=$BCM_GIT_DIR/project/tiers/$STACK_NAME/tier_profile.yml"

# next, provision (but not start) all LXC system containers across the cluster.
bash -c "$BCM_LXD_OPS/spread_lxc_hosts.sh --tier-name=$TIER_NAME"

# configure and start the containers
for ENDPOINT in $(bcm cluster list --endpoints); do
    HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
    
    # env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
    source ./env.sh --host-ending="$HOST_ENDING"
    
    TIER_BASE_NAME="$TIER_NAME"
    if [[ $TIER_NAME == bitcoin* ]]; then
        TIER_BASE_NAME=bitcoin
    fi
    
    # each tier has a specific daemon.json config
    DAEMON_JSON="$BCM_GIT_DIR/project/tiers/$TIER_BASE_NAME/daemon.json"
    if [ -f "$DAEMON_JSON" ]; then
        mkdir -p /tmp/bcm
        touch "/tmp/bcm/env"
        envsubst <"$DAEMON_JSON" >"/tmp/bcm/env"
        lxc file push "/tmp/bcm/env" "$LXC_HOSTNAME/etc/docker/daemon.json"
        rm "/tmp/bcm/env"
    fi
    # each tier can have a specific dhcp conf file, but it's optional due to default behavior.
    DHCPD_CONF_FILE="$BCM_GIT_DIR/project/tiers/$TIER_BASE_NAME/dhcp_conf.yml"
    if [[ -f "$DHCPD_CONF_FILE" ]]; then
        lxc file push "$DHCPD_CONF_FILE" "$LXC_HOSTNAME/etc/netplan/10-lxc.yaml"
    fi
    
    source "$BCM_GIT_DIR/project/tiers/$TIER_BASE_NAME/env"
    
    # TIER_TYPE of value 2 means one interface (eth1) in container is
    # using MACVLAN to expose services on the physical network underlay network.
    if [[ $BCM_TIER_TYPE == 2 ]]; then
        # if this tier is of type 2, then we need to source the endpoint tier .env then wire up the MACVLAN interface.
        ACTIVE_CLUSTER="$(lxc remote get-default)"
        
        ACTIVE_ENDPOINT="$ACTIVE_CLUSTER-01"
        ENDPOINT_ENV_PATH="$BCM_WORKING_DIR/$ACTIVE_CLUSTER/$ACTIVE_ENDPOINT/env"
        if [[ -f "$ENDPOINT_ENV_PATH" ]]; then
            source "$ENDPOINT_ENV_PATH"
            
            # wire up the interface if the MACVLAN_INTERFACE variable is defined.
            if [[ ! -z "$MACVLAN_INTERFACE" ]]; then
                if lxc network list --format csv | grep physical | grep -q "$MACVLAN_INTERFACE"; then
                    lxc config device add "$LXC_HOSTNAME" eth2 nic nictype=macvlan name=eth2 parent="$MACVLAN_INTERFACE"
                fi
            else
                echo "Error: MACVLAN_INTERFACE was not specified."
            fi
            
        else
            echo "ERROR: The '$ACTIVE_ENDPOINT/env' does not exist. Can't wire up the macvlan interface."
        fi
        
        # The above MACVLAN stuff allows us to expose services on the LAN, but we can't
        # access those services from the same host due to limitations in
        if [[ $(bcm cluster list --endpoints | wc -l) -gt 1 ]]; then
            # create the # localNet network across the cluster.
            for ENDPOINT in $(bcm cluster list --endpoints); do
                lxc network create --target "$ENDPOINT" bcmLocalnet
            done
        else
            if ! lxc network list --format csv | grep -q bcmLocalnet; then
                # but if it's just one node, we just create the network.
                lxc network create bcmLocalnet ipv4.nat=false ipv6.nat=false ipv6.address=none
            else
                echo "ERROR: The bcmLocalnet network was not in the proper state or doesn't exist."
                exit 1
            fi
        fi
    fi
    
    if lxc list --format csv --columns ns | grep "$LXC_HOSTNAME" | grep -q "STOPPED"; then
        # let's bring up the host then wait for dockerd to start.
        lxc start "$LXC_HOSTNAME"
        bash -c "$BCM_GIT_DIR/project/shared/wait_for_dockerd.sh --container-name=$LXC_HOSTNAME"
    fi
    
    # if TIER type is >=1 then we wait for gateway which is assumed to exist.
    # all nodes from this script are workers. Manager hosts are implemented
    # outside this script (see gateway).
    source ./get_docker_swarm_tokens.sh
    if [[ $BCM_TIER_TYPE -ge 1 ]]; then
        lxc exec "$LXC_HOSTNAME" -- wait-for-it -t 15 -q "$BCM_MANAGER_HOST_NAME":2377
        lxc exec "$LXC_HOSTNAME" -- wait-for-it -t 15 -q "$BCM_MANAGER_HOST_NAME":5000
        lxc exec "$LXC_HOSTNAME" -- docker swarm join --token "$DOCKER_SWARM_WORKER_JOIN_TOKEN" "$BCM_MANAGER_HOST_NAME":2377
    fi
done
