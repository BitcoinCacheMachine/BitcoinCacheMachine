#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_TIER_NAME=

for i in "$@"; do
    case $i in
        --tier-name=*)
            BCM_TIER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

# first, create the profile that represents the tier.
bash -c "$BCM_LXD_OPS/create_tier_profile.sh --tier-name=$BCM_TIER_NAME --yaml-path=$BCM_GIT_DIR/project/tiers/$BCM_TIER_NAME/tier_profile.yml"

# next, provision (but not start) all LXC system containers across the cluster.
bash -c "$BCM_LXD_OPS/spread_lxc_hosts.sh --tier-name=$BCM_TIER_NAME"

# Now, let's fetch the docker swarm token so we can start the rest of the tier.
# shellcheck disable=SC1090
if [[ $BCM_TIER_NAME != "gateway" ]]; then
    source "$BCM_LXD_OPS/get_docker_swarm_tokens.sh"
fi

# configure and start the containers
for ENDPOINT in $(bcm cluster list --endpoints); do
    HOST_ENDING=$(echo "$ENDPOINT" | tail -c 2)
    HOSTNAME="bcm-$BCM_TIER_NAME-$(printf %02d "$HOST_ENDING")"
    
    # each tier has a specific daemon.json config
    lxc file push "$BCM_GIT_DIR/project/tiers/$BCM_TIER_NAME/daemon.json" "$HOSTNAME/etc/docker/daemon.json"
    
    # each tier can have a specific dhcp conf file, but it's optional due to default behavior.
    DHCPD_CONF_FILE="$BCM_GIT_DIR/project/tiers/$BCM_TIER_NAME/dhcp_conf.yml"
    if [[ -f "$DHCPD_CONF_FILE" ]]; then
        lxc file push "$DHCPD_CONF_FILE" "$HOSTNAME/etc/netplan/10-lxc.yaml"
    fi
    
    # let's source the tier and get required config variables.
    # shellcheck disable=1090
    source "$BCM_GIT_DIR/project/tiers/$BCM_TIER_NAME/env"
    
    # TIER_TYPE of value 2 means one interface (eth1) in container is
    # using MACVLAN to expose services to the physical network underlay
    if [[ $BCM_TIER_TYPE == 2 ]]; then
        # if this tier is of type 2, then we need to source the endpoint tier .env then wire up the MACVLAN interface.
        if lxc network list --format csv | grep physical | grep -q "$MACVLAN_INTERFACE"; then
            lxc config device add "$HOSTNAME" eth1 nic nictype=macvlan name=eth1 parent="$MACVLAN_INTERFACE"
        fi
    fi
    
    if lxc list --format csv --columns ns | grep "$HOSTNAME" | grep -q "STOPPED"; then
        # let's bring up the host then wait for dockerd to start.
        lxc start "$HOSTNAME"
    fi
    
    bash -c "$BCM_GIT_DIR/project/shared/wait_for_dockerd.sh --container-name=$HOSTNAME"
    
    # if TIER type is >=1 then we wait for gateway which is assumed to exist.
    # all nodes from this script are workers. Manager hosts are implemented
    # outside this script (see gateway).
    if [[ $BCM_TIER_TYPE -ge 1 ]]; then
        if lxc exec "$HOSTNAME" -- docker info | grep "Swarm: " | grep -q "inactive"; then
            lxc exec "$HOSTNAME" -- wait-for-it -t 0 -q bcm-gateway-01:2377
            lxc exec "$HOSTNAME" -- wait-for-it -t 0 -q bcm-gateway-01:5000
            lxc exec "$HOSTNAME" -- docker swarm join --token "$DOCKER_SWARM_WORKER_JOIN_TOKEN" bcm-gateway-01:2377
        fi
    fi
done
