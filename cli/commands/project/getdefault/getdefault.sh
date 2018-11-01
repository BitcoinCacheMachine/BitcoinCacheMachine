#!/bin/bash


if [[ ! -f ~/.bcm/projects/bcm.client.sh ]]; then
    touch ~/.bcm/projects/bcm.client.sh
    chmod +x ~/.bcm/projects/bcm.client.sh
fi

if [[ -z $BCM_DIRECTORY_FLAG ]]; then
    BCM_DIRECTORY_FLAG=0
fi

source ~/.bcm/projects/bcm.client.sh

#echo "BCM_DIRECTORY_FLAG: $BCM_DIRECTORY_FLAG"

if [[ ! -z $BCM_PROJECT_NAME ]]; then
    if [[ $BCM_DIRECTORY_FLAG = 1 ]]; then
        echo ~/.bcm/projects/$BCM_PROJECT_NAME
    else
        echo "$BCM_PROJECT_NAME"
    fi    
fi
