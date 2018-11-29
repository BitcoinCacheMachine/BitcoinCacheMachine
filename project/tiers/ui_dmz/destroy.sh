#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

bash -c ./stacks/connect_ui/destroy_connect_ui.sh
bash -c ./stacks/control_center/destroy_control_center.sh
bash -c ./stacks/schema_registry_ui/destroy_schema_registry_ui.sh
bash -c ./stacks/topics_ui/destroy_topics_ui.sh

# iterate over endpoints and delete relevant resources
for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    #echo $endpoint
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    HOST="bcm-uidmz-$(printf %02d "$HOST_ENDING")"

    if [[ ! -z $(lxc list | grep "$HOST") ]]; then
        lxc delete "$HOST" --force
    fi

    bash -c "$BCM_LXD_OPS/delete_cluster_dockerdisk.sh --container-name=$HOST --endpoint=$endpoint"
done
