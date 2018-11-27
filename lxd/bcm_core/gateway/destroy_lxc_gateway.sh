#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

#MASTER_NODE=$(lxc info | grep server_name | xargs | awk 'NF>1{print $NF}')
for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    #echo $endpoint
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    GATEWAY_HOST="bcm-gateway-$(printf %02d "$HOST_ENDING")"

    bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_container.sh --container-name=$GATEWAY_HOST"
done

bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_cluster_dockerdisk.sh --volume-name=bcm-gateway"

BCM_GATEWAY_CONTAINER_TEMPLATE_DELETE=0
if [[ $BCM_GATEWAY_CONTAINER_TEMPLATE_DELETE = 1 ]]; then
    if ! lxc list | grep -q "bcm-template"; then
        lxc delete bcm-template --force
    fi
fi

bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_network.sh --network-name=bcmbrGWNat"

bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_network.sh --network-name=bcmNet"

bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_image.sh --image-name=bcm-gateway-template"

bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_profile.sh --profile-name=bcm_gateway_profile"