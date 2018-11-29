#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")" 


BCM_TIER_NAME=

for i in "$@"
do
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


# first let's install the profile for the TIER.
PROFILE_NAME='bcm_'"$BCM_TIER_NAME"'_profile'
if ! lxc profile list | grep -q "$PROFILE_NAME"; then
    lxc profile create "$PROFILE_NAME"
fi

# apply the default kafka.yml
lxc profile edit "$PROFILE_NAME" < "./$BCM_TIER_NAME/tier_profile.yml"

# get all the bcm-kafka-xx containers deployed to the cluster.
bash -c "$BCM_LXD_OPS/spread_lxc_hosts.sh --tier-name=$BCM_TIER_NAME"

# shellcheck disable=SC1090
source "$BCM_LXD_OPS/get_docker_swarm_tokens.sh"

# start the containers
for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    HOSTNAME="bcm-$BCM_TIER_NAME-$(printf %02d "$HOST_ENDING")"
    
    lxc file push "./$BCM_TIER_NAME/daemon.json" "$HOSTNAME/etc/docker/daemon.json"
    
    DHCPD_CONF_FILE="./$BCM_TIER_NAME/dhcp_conf.yml"
    if [[ -f $DHCPD_CONF_FILE ]]; then
        lxc file push "$DHCPD_CONF_FILE" "$HOSTNAME/etc/netplan/10-lxc.yaml"
    fi

    source "./$BCM_TIER_NAME/tier.env"
    if [[ $BCM_TIER_TYPE = 2 ]]; then
        # if this tier is of type 2, then we need to source the endpoint tier .env then wire up the MACVLAN interface.
        source "$BCM_RUNTIME_DIR/clusters/$BCM_CLUSTER_NAME/endpoints/$endpoint/.env"
        lxc config device add "$HOSTNAME" eth1 nic nictype=macvlan parent="$BCM_LXD_PHYSICAL_INTERFACE" name=eth1 
    fi

    lxc start "$HOSTNAME"

    bash -c "$BCM_LOCAL_GIT_REPO_DIR/project/shared/wait_for_dockerd.sh --container-name=$HOSTNAME"
    
    # if TIER type is >=1 then we wait for gateway
    if [[ $BCM_TIER_TYPE -ge 1 ]]; then
        lxc exec "$HOSTNAME" -- wait-for-it -t 0 bcm-gateway-01:2377
        lxc exec "$HOSTNAME" -- wait-for-it -t 0 bcm-gateway-01:5000
        lxc exec "$HOSTNAME" -- docker swarm join --token "$DOCKER_SWARM_WORKER_JOIN_TOKEN" bcm-gateway-01:2377
    fi
done

bash -c "./$BCM_TIER_NAME/up.sh"