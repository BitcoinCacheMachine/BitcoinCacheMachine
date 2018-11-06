#!/bin/bash

PROJECTS_DIR=$BCM_RUNTIME_DIR/projects
if [[ ! -f $PROJECTS_DIR/bcm.client.sh ]]; then
    touch $PROJECTS_DIR/bcm.client.sh
    chmod +x $PROJECTS_DIR/bcm.client.sh
fi

if [[ -z $BCM_DIRECTORY_FLAG ]]; then
    BCM_DIRECTORY_FLAG=0
fi

source $PROJECTS_DIR/bcm.client.sh

#echo "BCM_DIRECTORY_FLAG: $BCM_DIRECTORY_FLAG"

if [[ ! -z $BCM_PROJECT_NAME ]]; then
    if [[ $BCM_DIRECTORY_FLAG = 1 ]]; then
        echo $PROJECTS_DIR/$BCM_PROJECT_NAME
    else
        echo "$BCM_PROJECT_NAME"
    fi
fi
