#!/bin/bash

set -eu

if [[ -z $BCM_GIT_REPO_DIR ]]; then
    echo "Required parameter BCM_GIT_REPO_DIR not specified."
    exit
else
    if [[ -d "$BCM_GIT_REPO_DIR" ]]; then
        export BCM_GIT_REPO_DIR=$BCM_GIT_REPO_DIR
    else
        echo "BCM_GIT_REPO_DIR does not appear to exist."
        exit
    fi
fi