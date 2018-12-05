#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source ./.env

bcm project undeploy --project-name="$BCM_PROJECT_NAME" --cluster-name="$BCM_CLUSTER_NAME" --remove-template

bcm cluster destroy --cluster-name="$BCM_CLUSTER_NAME"

bcm project destroy --project-name="$BCM_PROJECT_NAME"

CERT_DIR="$BCM_RUNTIME_DIR/certs/trezor/"
if [[ -d $CERT_DIR ]]; then
    sudo rm -Rf "$CERT_DIR"
    echo "" > "$BCM_RUNTIME_DIR/certs/.env"
fi

# this resets the lxd configuration to defaults.
sudo lxd init --preseed < "$BCM_GIT_DIR/cluster/lxd_preseed/blank.yml"