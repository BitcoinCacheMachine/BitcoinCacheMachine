#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1090
source "$BCM_GIT_DIR/.env"

bcm project undeploy --project-name="$BCM_PROJECT_NAME" --cluster-name="$BCM_CLUSTER_NAME" --remove-template

bcm cluster destroy --cluster-name="$BCM_CLUSTER_NAME"

CERT_DIR="$BCM_RUNTIME_DIR"
if [[ -d $BCM_RUNTIME_DIR/encrypted ]]; then
	fusermount -u "$BCM_RUNTIME_DIR/encrypted"
fi

sudo rm -Rf "$CERT_DIR"
# this resets the lxd configuration to defaults.
# sudo lxd init --preseed < "$BCM_GIT_DIR/cluster/lxd_preseed/blank.yml"
