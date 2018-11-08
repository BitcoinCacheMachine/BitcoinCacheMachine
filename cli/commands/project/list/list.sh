#!/bin/bash

set -eu

if [[ ! -d $BCM_PROJECTS_DIR ]]; then
    echo "$BCM_PROJECTS_DIR does not exist. You may need to re-run 'bcm init'."
    exit
fi

if [[ $BCM_DEPLOYMENTS_FLAG = 1 ]]; then
    # Let's display the deployed endpoints.
    cd $BCM_DEPLOYMENTS_DIR >>/dev/null
    for deployment in $(ls -l | grep '^d' | awk 'NF>1{print $NF}'); do
        echo "$deployment"
    done
    cd - >>/dev/null
else
    cd $BCM_PROJECTS_DIR >>/dev/null
    for project in $(ls -l | grep '^d' | awk 'NF>1{print $NF}'); do
        echo "$project"
    done
    cd - >>/dev/null
fi