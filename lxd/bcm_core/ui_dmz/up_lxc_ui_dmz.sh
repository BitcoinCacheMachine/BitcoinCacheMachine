#!/usr/bin/env bash

set -Eeuox pipefail
cd "$(dirname "$0")" 

# create the 'bcm_ui_dmz' lxc profile
if ! lxc profile list | grep -q "bcm_uidmz_profile"; then
    lxc profile create bcm_uidmz_profile
fi

# apply the default kafka.yml
lxc profile edit bcm_uidmz_profile < ./lxd_profiles/bcm_ui_dmz.yml

# get all the bcm-kafka-xx containers deployed to the cluster.
bash -c "$BCM_LXD_OPS/spread_lxc_hosts.sh --hostname=uidmz --apply-profile=bcm_uidmz_profile"

# shellcheck disable=SC1090
source "$BCM_LXD_OPS/get_docker_swarm_tokens.sh"

# start the containers
for endpoint in $(bcm cluster list --endpoints --cluster-name="$BCM_CLUSTER_NAME"); do
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    HOSTNAME="bcm-uidmz-$(printf %02d "$HOST_ENDING")"
    lxc file push ./uidmz.daemon.json "$HOSTNAME/etc/docker/daemon.json"
    lxc file push ./dhcp_conf.yml "$HOSTNAME/etc/netplan/10-lxc.yaml"

    source "$BCM_RUNTIME_DIR/clusters/$BCM_CLUSTER_NAME/endpoints/$endpoint/.env"

    lxc config device add "$HOSTNAME" eth1 nic nictype=macvlan parent="$BCM_LXD_PHYSICAL_INTERFACE" name=eth1 

    lxc start "$HOSTNAME"

    ../../shared/wait_for_dockerd.sh --container-name="$HOSTNAME"
    
    # make sure gateway and kafka hosts can reach the swarm master.
    # this steps helps resolve networking before we issue any meaningful
    # commands.
    lxc exec "$HOSTNAME" -- wait-for-it -t 0 bcm-gateway-01:2377
    lxc exec "$HOSTNAME" -- wait-for-it -t 0 bcm-gateway-01:5000

    # All other LXD bcm-kafka nodes are workers.
    lxc exec "$HOSTNAME" -- docker swarm join --token "$DOCKER_SWARM_WORKER_JOIN_TOKEN" bcm-gateway-01:2377
done

bash -c ./connect_ui/up_connect_ui.sh
bash -c ./control_center/up_control_center.sh
bash -c ./schema_registry_ui/up_schema_registry_ui.sh
bash -c ./topics_ui/up_topics_ui.sh