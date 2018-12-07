#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1090
source "$BCM_GIT_DIR/.env"
echo "BCM_FORCE_FLAG: $BCM_FORCE_FLAG"
# shellcheck disable=2153
BCM_DEPLOYMENT_DIR="$BCM_DEPLOYMENTS_DIR/$BCM_PROJECT_NAME""_""$BCM_CLUSTER_NAME"
if [[ ! -d $BCM_DEPLOYMENT_DIR && $BCM_FORCE_FLAG == 0 ]]; then
	echo "BCM Deployment directory '$BCM_DEPLOYMENT_DIR' does not exist. Exiting"
	exit
else
	bash -c "$BCM_GIT_DIR/project/destroy.sh"

	if [[ -d "$BCM_DEPLOYMENT_DIR" ]]; then
		sudo rm -Rf "$BCM_DEPLOYMENT_DIR"
	fi
fi
