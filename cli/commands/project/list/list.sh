#!/bin/bash

set -eu
cd "$(dirname "$0")"

if [[ $BCM_HELP_FLAG = 1 ]]; then
    cat ./help.txt
    exit
fi

if [[ ! -d $BCM_PROJECTS_DIR ]]; then
    echo "$BCM_PROJECTS_DIR does not exist. You may need to re-run 'bcm init'."
    exit
fi

if [[ $BCM_DEPLOYMENTS_FLAG = 1 ]]; then
    if [[ -z $BCM_PROJECT_NAME ]]; then
        echo "BCM_PROJECT_NAME must be set."
        cat ./help.txt
        exit
    fi
    
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