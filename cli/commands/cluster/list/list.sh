#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

if [[ $BCM_HELP_FLAG = 1 ]]; then
    cat ./help.txt
    exit
fi

if [[ ! -d $BCM_CLUSTERS_DIR ]]; then
    echo "$BCM_CLUSTERS_DIR does not exist. You may need to re-run 'bcm init'."
    exit
fi

if [[ $BCM_ENDPOINTS_FLAG = 1 ]]; then
    if [[ -z $BCM_CLUSTER_NAME ]]; then
        echo "BCM_CLUSTER_NAME must be set."
        cat ./help.txt
        exit
    fi
    
    # Let's display the deployed endpoints.
    cd $BCM_CLUSTERS_DIR/$BCM_CLUSTER_NAME/endpoints >>/dev/null
    for clusterEndpoint in $(ls -l | grep '^d' | awk 'NF>1{print $NF}'); do
        echo "$clusterEndpoint"
    done
    cd - >>/dev/null
else
    cd $BCM_CLUSTERS_DIR >>/dev/null
    for cluster in $(ls -l | grep '^d' | awk 'NF>1{print $NF}'); do
        echo "$cluster"
    done
    cd - >>/dev/null
fi