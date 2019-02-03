#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=1090
source "$BCM_GIT_DIR/env"


if [[ -z $BCM_CLUSTER_NAME ]]; then
    echo "BCM_CLUSTER_NAME not set. Exiting."
    exit
fi

# Ensure the endpoint name is in our env.
if [[ -e $BCM_ENDPOINT_NAME ]]; then
    echo "BCM_ENDPOINT_NAME variable not set."
    exit
fi