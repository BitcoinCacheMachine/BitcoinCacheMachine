#!/bin/bash

set -eu
cd "$(dirname "$0")"
source ./env.sh

bcm project undeploy --project-name="$BCM_PROJECT_NAME" --cluster-name="$BCM_CLUSTER_NAME"

bcm project destroy --project-name="$BCM_PROJECT_NAME"

bcm cluster destroy --cluster-name="$BCM_CLUSTER_NAME"

sudo rm -Rf $BCM_RUNTIME_DIR

$BCM_LOCAL_GIT_REPO_DIR/cluster/providers/lxd/snap_lxd_uninstall.sh

sleep 5

if [[ ! -z $(zpool list | grep "bcm_zfs") ]]; then 
    sudo zpool destroy bcm_zfs
fi