#!/bin/bash

set -eu

if [[ ! -d $BCM_CLUSTER_DIR ]]; then
    mkdir -p $BCM_CLUSTER_DIR
fi

if [[ $(ls -l $BCM_CLUSTER_DIR | grep -c ^d) = "0" ]]; then
    exit
else
    cd $BCM_CLUSTER_DIR
    for cluster in `ls -d */ | sed 's/.$//'`; do
        if [[ ! -z $cluster ]]; then
            if [[ $BCM_SHOW_ENDPOINTS_FLAG = 1 ]]; then
                if [[ ! -z $BCM_CLUSTER_NAME ]]; then
                    if [[ $BCM_CLUSTER_NAME = "$cluster" ]]; then
                        ENDPOINTS_DIR=$BCM_BCM_CLUSTER_DIR/
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