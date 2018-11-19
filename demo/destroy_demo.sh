#!/bin/bash

set -eu
cd "$(dirname "$0")"
source ./env.sh

bcm project undeploy --project-name="$BCM_PROJECT_NAME" --cluster-name="$BCM_CLUSTER_NAME" --remove-template

bcm cluster destroy --cluster-name="$BCM_CLUSTER_NAME"

bcm project destroy --project-name="$BCM_PROJECT_NAME"

sudo rm -Rf $BCM_RUNTIME_DIR/certs/trezor/

#$BCM_LOCAL_GIT_REPO_DIR/cluster/providers/lxd/snap_lxd_uninstall.sh
