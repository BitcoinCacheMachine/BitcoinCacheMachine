#!/bin/bash

set -Eeuox pipefail
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

if [[ -z $BCM_TIER_NAME ]]; then
    echo "BCM_TIER_NAME is empty. Exiting"
    exit
fi

bash -c "./$BCM_TIER_NAME/destroy.sh"

# iterate over endpoints and delete actual LXC hosts.
for LXD_ENDPOINT in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    HOST_ENDING=$(echo "$LXD_ENDPOINT" | tail -c 2)
    LXC_HOST="bcm-$BCM_TIER_NAME-$(printf %02d "$HOST_ENDING")"
    bash -c "$BCM_LXD_OPS/remove_docker_node.sh --node-name=$LXC_HOST"
    bash -c "$BCM_LXD_OPS/delete_lxc_container.sh --container-name=$LXC_HOST"
    bash -c "$BCM_LXD_OPS/delete_cluster_dockerdisk.sh --container-name=$LXC_HOST --endpoint=$LXD_ENDPOINT"
done

PROFILE_NAME='bcm_'"$BCM_TIER_NAME"'_profile'
if lxc profile list | grep -q "$PROFILE_NAME"; then
    lxc profile delete "$PROFILE_NAME"
fi