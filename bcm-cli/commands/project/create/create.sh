#!/bin/bash

set -eu

cd "$(dirname "$0")"

function printhelp {
    printf "\n" && echo "$(cat ./help.txt)"
}

if [[ ! -z $BCM_PROJECT_NAME ]]; then
    BCM_PROJECT_NAME=$BCM_PROJECT_NAME
    BCM_PROJECT_BASE_DIR=~/.bcm/projects
    BCM_PROJECT_DIR=$BCM_PROJECT_BASE_DIR/$BCM_PROJECT_NAME
    
    # if the directory already exists we're going to quit
    if [[ -d $BCM_PROJECT_DIR ]]; then
        echo "BCM project directory already exists. If you want to remove it, run 'bcm project destroy $BCM_PROJECT_NAME'"
        exit
    fi

    echo "BCM_PROJECT_NAME: '$BCM_PROJECT_NAME'"
    echo "BCM_PROJECT_DIR: '$BCM_PROJECT_DIR'"

    # if $BCM_PROJECT_BASE_DIR doesn't exist, create it.
    if [ ! -d $BCM_PROJECT_BASE_DIR ]; then
        echo "Creating lxd_projects directory at $BCM_PROJECT_BASE_DIR"
        mkdir -p $BCM_PROJECT_BASE_DIR
    fi
    
    # if ~/.bcm/projects doesn't exist, create it.
    if [ ! -d $BCM_PROJECT_DIR ]; then
        echo "Creating bcm project directory at $BCM_PROJECT_DIR"
        mkdir -p $BCM_PROJECT_DIR
    fi

    if [[ -z $BCM_PROJECT_USERNAME ]]; then
        echo "Error: BCM_PROJECT_USERNAME is required."
        printhelp
        exit
    fi

    if [[ -z $BCM_PROJECT_CLUSTERNAME ]]; then
        echo "Error: BCM_PROJECT_CLUSTERNAME is required."
        printhelp
        exit
    fi

    echo "BCM_PROJECT_USERNAME: '$BCM_PROJECT_USERNAME'"
    echo "BCM_PROJECT_CLUSTERNAME: '$BCM_PROJECT_CLUSTERNAME'"
    
    export BCM_PROJECT_NAME=$BCM_PROJECT_NAME
    export BCM_PROJECT_DIR=$BCM_PROJECT_DIR
    export BCM_PROJECT_USERNAME=$BCM_PROJECT_USERNAME
    export BCM_PROJECT_CLUSTERNAME=$BCM_PROJECT_CLUSTERNAME
    export BCM_TREZOR_USB_PATH=$BCM_TREZOR_USB_PATH
    
    $BCM_LOCAL_GIT_REPO/trezor/gpg-init.sh

    # let's just do a quick spot check to ensure the directory exists.
    if [[ -d $BCM_PROJECT_DIR/trezor ]]; then
        bash -c "$BCM_LOCAL_GIT_REPO/bcm-cli/bcm.sh project set-default $BCM_PROJECT_NAME"
    fi
else
    echo "Error: BCM_PROJECT_NAME is required."
    printhelp
    exit
fi