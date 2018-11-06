#!/bin/bash

set -eu


CLUSTERS_DIR="$BCM_RUNTIME_DIR/clusters"
if [[ ! -d $CLUSTERS_DIR ]]; then
    mkdir -p $CLUSTERS_DIR
fi

if [[ $(ls -l $CLUSTERS_DIR | grep -c ^d) = "0" ]]; then
    exit
else
    cd $CLUSTERS_DIR
    for cluster in `ls -d */ | sed 's/.$//'`; do
        if [[ ! -z $cluster ]]; then
            if [[ $BCM_SHOW_ENDPOINTS_FLAG = 1 ]]; then
                if [[ ! -z $BCM_CLUSTER_NAME ]]; then
                    if [[ $BCM_CLUSTER_NAME = "$cluster" ]]; then
                        ENDPOINTS_DIR=$BCM_RUNTIME_DIR/clusters/$cluster/endpoints
                        if [[ $(ls -l $ENDPOINTS_DIR | grep -c ^d) = "0" ]]; then
                            exit
                        else
                            cd $ENDPOINTS_DIR
                            for endpoint in `ls -d */ | sed 's/.$//'`; do
                                echo "$endpoint"
                            done
                            cd - >> /dev/null
                        fi
                    fi
                else
                    echo "BCM_CLUSTER_NAME flag was set to true, but no cluster name was given."
                fi
            else
                echo "$cluster"
            fi
        fi
    done
    cd - >> /dev/null
fi