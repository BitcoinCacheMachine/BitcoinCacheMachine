#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source "$BCM_GIT_DIR/.env"

if [[ $BCM_HELP_FLAG = 1 ]]; then
    cat ./help.txt
    exit
fi

if [[ $BCM_ENDPOINTS_FLAG = 1 ]]; then
    if [[ -z $BCM_CLUSTER_NAME ]]; then
        exit
    fi
    
    # Let's display the deployed endpoints.
    ENDPOINTS_DIR="$BCM_CLUSTERS_DIR/$BCM_CLUSTER_NAME/endpoints"
    find "$ENDPOINTS_DIR/" -mindepth 1 -maxdepth 1 -type d -printf '%f\n'
else
    #echo "$(pwd)"
    #echo "$BCM_CLUSTERS_DIR"
    # CLUSTERS="$(echo $BCM_CLUSTERS_DIR/*/)"
    find "$BCM_CLUSTERS_DIR/" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | grep -v ".git"
fi