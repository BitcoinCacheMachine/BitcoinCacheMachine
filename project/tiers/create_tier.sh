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

# first, create the profile that represents the tier.
./create_tier_profile.sh --tier-name="$TIER_NAME"

# next, provision (but not start) all LXC system containers across the cluster.
./spread_lxc_hosts.sh --tier-name="$TIER_NAME"

# configure and start the LXC containers
for ENDPOINT in $CLUSTER_ENDPOINTS; do
    HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
    
    # The bcmLocalnet network allows users to access services from the same
    # host as where bcm back-end services are running (rather than from the network or onion)
    if [[ $CLUSTER_NODE_COUNT -gt 1 ]]; then
        lxc network create --target "$ENDPOINT" bcmLocalnet
    fi
    
    # env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
    source ./env.sh --host-ending="$HOST_ENDING"
    
    TIER_BASE_NAME="$TIER_NAME"
    if [[ $TIER_NAME == bitcoin* ]]; then
        TIER_BASE_NAME=bitcoin
    fi
    
    # each tier has a specific daemon.json config
    DAEMON_JSON="$BCM_GIT_DIR/project/tiers/$TIER_BASE_NAME/daemon.json"
    if [ -f "$DAEMON_JSON" ]; then
        touch "$BCM_TMP_DIR/env"
        envsubst <"$DAEMON_JSON" >"$BCM_TMP_DIR/env"
        lxc file push "$BCM_TMP_DIR/env" "$LXC_HOSTNAME/etc/docker/daemon.json"
        rm "$BCM_TMP_DIR/env"
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
        # get the MACVLAN interface (the localhost's default gateway)
        BCM_MACVLAN_INTERFACE="$(ip route | grep default | cut -d " " -f 5)"
        
        # wire up the interface if the BCM_MACVLAN_INTERFACE variable is defined.
        if [[ ! -z "$BCM_MACVLAN_INTERFACE" ]]; then
            if lxc network list --format csv | grep physical | grep -q "$BCM_MACVLAN_INTERFACE"; then
                lxc config device add "$LXC_HOSTNAME" eth2 nic nictype=macvlan name=eth2 parent="$BCM_MACVLAN_INTERFACE"
            fi
        else
            echo "Error: BCM_MACVLAN_INTERFACE was not specified."
        fi
        
        
        if ! lxc network list --format csv | grep -q bcmLocalnet; then
            # but if it's just one node, we just create the network.
            lxc network create bcmLocalnet ipv4.nat=false ipv6.nat=false ipv6.address=none
        else
            echo "ERROR: The bcmLocalnet network was not in the proper state or doesn't exist."
            exit 1
        fi
    fi
    
    if lxc list --format csv --columns ns | grep "$LXC_HOSTNAME" | grep -q "STOPPED"; then
        # let's bring up the host then wait for dockerd to start.
        lxc start "$LXC_HOSTNAME"
        bash -c "$BCM_LXD_OPS/wait_for_dockerd.sh --container-name=$LXC_HOSTNAME"
    fi
    
    # if TIER type is >=1 then we wait for manager which is assumed to exist.
    # all nodes from this script are workers. Manager hosts are implemented
    # outside this script (see manager).
    source "$BCM_GIT_DIR/project/tiers/get_docker_swarm_tokens.sh"
    if [[ $BCM_TIER_TYPE -ge 1 ]]; then
        lxc exec "$LXC_HOSTNAME" -- wait-for-it -t 15 -q "$BCM_MANAGER_HOST_NAME":2377
        lxc exec "$LXC_HOSTNAME" -- wait-for-it -t 15 -q "$BCM_MANAGER_HOST_NAME:$BCM_REGISTRY_MIRROR_PORT"
        
        # TODO fix this so we check to see if the engine is NOT part of the swarm yet. then remove || true
        lxc exec "$LXC_HOSTNAME" -- docker swarm join --token "$DOCKER_SWARM_WORKER_JOIN_TOKEN" "$BCM_MANAGER_HOST_NAME":2377 || true
    fi
done
