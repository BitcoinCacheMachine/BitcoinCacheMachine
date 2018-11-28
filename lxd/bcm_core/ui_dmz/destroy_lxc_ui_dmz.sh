#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

bash -c ./connect_ui/destroy_connect_ui.sh
bash -c ./control_center/destroy_control_center.sh
bash -c ./schema_registry_ui/destroy_schema_registry_ui.sh
bash -c ./topics_ui/destroy_topics_ui.sh

# iterate over endpoints and delete relevant resources
for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    #echo $endpoint
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    HOST="bcm-uidmz-$(printf %02d "$HOST_ENDING")"

    if [[ ! -z $(lxc list | grep "$HOST") ]]; then
        lxc delete "$HOST" --force
    fi

    if [[ ! -z $(lxc storage volume list "bcm_btrfs" | grep "$HOST-dockerdisk") ]]; then
        lxc storage volume delete "bcm_btrfs" "$HOST-dockerdisk" --target "$endpoint"
    fi
done

if lxc profile list | grep -q "bcm_uidmz_profile"; then
    lxc profile delete bcm_uidmz_profile
fi
