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
        echo "BCM_CLUSTER_NAME must be set."
        cat ./help.txt
        exit
    fi
    
    # Let's display the deployed endpoints.
    ENDPOINTS_DIR="$BCM_CLUSTERS_DIR/$BCM_CLUSTER_NAME/endpoints"
    if [[ -d $ENDPOINTS_DIR ]]; then
        cd $ENDPOINTS_DIR >>/dev/null
        for ENDPOINT in $(ls -l | grep '^d' | awk 'NF>1{print $NF}'); do
            echo "$ENDPOINT"
        done
        cd - >>/dev/null
    fi
else
    cd $BCM_CLUSTERS_DIR >>/dev/null
    for cluster in $(ls -l | grep '^d' | awk 'NF>1{print $NF}'); do
        echo "$cluster"
    done
    cd - >>/dev/null
fi