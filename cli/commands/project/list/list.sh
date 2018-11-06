#!/bin/bash

set -eu

BCM_PROJECTS_DIR="$BCM_RUNTIME_DIR/projects"
if [[ ! -d $BCM_PROJECTS_DIR ]]; then
    echo "$BCM_PROJECTS_DIR does not exist. You may need to re-run 'bcm init'."
    exit
fi

echo "BCM_PROJECTS_DIR: $BCM_PROJECTS_DIR"
if [[ $(ls -l $BCM_PROJECTS_DIR | grep -c ^d) = "0" ]]; then
    # this means the directory is empty and we're going to return nothing
    exit
else
    cd $BCM_PROJECTS_DIR
    echo "in $BCM_PROJECTS_DIR"
    for project in `ls -d */ | sed 's/.$//'`; do
        echo "$project"
    done
    cd - >> /dev/null
fi