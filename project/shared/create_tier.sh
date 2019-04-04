#!/bin/bash

set -Eeuox pipefail
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
bash -c "$BCM_LXD_OPS/create_tier_profile.sh --tier-name=$TIER_NAME --yaml-path=$BCM_GIT_DIR/project/tiers/$TIER_NAME/tier_profile.yml"

# next, provision (but not start) all LXC system containers across the cluster.
bash -c "$BCM_LXD_OPS/spread_lxc_hosts.sh --tier-name=$TIER_NAME"

# Now, let's fetch the docker swarm token so we can start the rest of the tier.
# shellcheck disable=SC1090
if [[ $TIER_NAME != "gateway" ]]; then
    source "$BCM_LXD_OPS/get_docker_swarm_tokens.sh"
fi

# configure and start the containers
for ENDPOINT in $(bcm cluster list --endpoints); do
    HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
    
    # env.sh has some of our naming conventions for DOCKERVOL and HOSTNAMEs and such.
    source ./env.sh --host-ending="$HOST_ENDING"
    
    # each tier has a specific daemon.json config
    DAEMON_JSON="$BCM_GIT_DIR/project/tiers/$TIER_NAME/daemon.json"
    if [ -f "$DAEMON_JSON" ]; then
        mkdir -p /tmp/bcm
        touch "/tmp/bcm/env"
        envsubst <"$DAEMON_JSON" >"/tmp/bcm/env"
        lxc file push "/tmp/bcm/env" "$LXC_HOSTNAME/etc/docker/daemon.json"
        #rm "/tmp/bcm/env"
    fi
    # each tier can have a specific dhcp conf file, but it's optional due to default behavior.
    DHCPD_CONF_FILE="$BCM_GIT_DIR/project/tiers/$TIER_NAME/dhcp_conf.yml"
    if [[ -f "$DHCPD_CONF_FILE" ]]; then
        lxc file push "$DHCPD_CONF_FILE" "$LXC_HOSTNAME/etc/netplan/10-lxc.yaml"
    fi
    
    # let's source the tier and get required config variables.
    # shellcheck disable=1090
    source "$BCM_GIT_DIR/project/tiers/$TIER_NAME/env"
    
    # TIER_TYPE of value 2 means one interface (eth1) in container is
    # using MACVLAN to expose services on the physical network underlay network.
    if [[ $BCM_TIER_TYPE == 2 ]]; then
        # if this tier is of type 2, then we need to source the endpoint tier .env then wire up the MACVLAN interface.
        ACTIVE_CLUSTER="$(lxc remote get-default)"
        ACTIVE_ENDPOINT="$ACTIVE_CLUSTER-$(printf %02d "$HOST_ENDING")"
        ENDPOINT_ENV_PATH="$BCM_WORKING_DIR/$ACTIVE_CLUSTER/$ACTIVE_ENDPOINT/env"
        if [[ -f "$ENDPOINT_ENV_PATH" ]]; then
            source "$ENDPOINT_ENV_PATH"
            
            # wire up the interface if the MACVLAN_INTERFACE variable is defined.
            if [[ ! -z "$MACVLAN_INTERFACE" ]]; then
                if lxc network list --format csv | grep physical | grep -q "$MACVLAN_INTERFACE"; then
                    lxc config device add "$LXC_HOSTNAME" eth1 nic nictype=macvlan name=eth1 parent="$MACVLAN_INTERFACE"
                fi
            else
                echo "ERROR: MACVLAN_INTERFACE was not specified."
            fi
        else
            echo "ERROR: The '$ACTIVE_ENDPOINT/env' does not exist. Can't wire up the macvlan interface."
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
    if [[ $BCM_TIER_TYPE -ge 1 ]]; then
        if lxc exec "$LXC_HOSTNAME" -- docker info | grep "Swarm: " | grep -q "inactive"; then
            lxc exec "$LXC_HOSTNAME" -- wait-for-it -t 15 -q "$BCM_GATEWAY_HOST_NAME":2377
            lxc exec "$LXC_HOSTNAME" -- wait-for-it -t 15 -q "$BCM_GATEWAY_HOST_NAME":5000
            lxc exec "$LXC_HOSTNAME" -- docker swarm join --token "$DOCKER_SWARM_WORKER_JOIN_TOKEN" "$BCM_GATEWAY_HOST_NAME":2377
        fi
    fi
done
