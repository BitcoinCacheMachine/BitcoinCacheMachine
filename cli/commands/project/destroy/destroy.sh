#!/bin/bash

DIR=$BCM_RUNTIME_DIR/projects/$BCM_PROJECT_NAME

if [[ ! -d $DIR ]]; then
    echo "BCM project directory $DIR does not exist. Nothing deleted."
    exit
fi

function deleteBCMProject {
    if [[ -d $DIR ]]; then
        sudo rm -rf $DIR
        rm "$BCM_RUNTIME_DIR/projects/bcm.client.sh"
        echo "Deleted contents of $DIR. Note $BCM_RUNTIME_DIR is a git repository and manages versions and history of all files."
    fi
}

CONTINUE=0
if [[ $BCM_FORCE_FLAG = "false" ]]; then
    read -p "Are you sure you want to delete the BCM project? [y/n]:  " choice
    case "$choice" in 
        y|Y ) CONTINUE=1;;
        * ) echo "invalid";;
    esac
else
    CONTINUE=1
fi

if [[ $CONTINUE = 1 ]]; then
    echo ""
    deleteBCMProject
    echo ""
fi