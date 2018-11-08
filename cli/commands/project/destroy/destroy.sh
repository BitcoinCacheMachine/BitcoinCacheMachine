#!/bin/bash

BCM_PROJECT_DIR=$BCM_PROJECTS_DIR/$BCM_PROJECT_NAME

if [[ ! -d $BCM_PROJECT_DIR ]]; then
    echo "BCM project definition '$BCM_PROJECT_NAME' does not exist. Nothing deleted."
    exit
fi

function deleteBCMProject {
    if [[ -d $BCM_PROJECT_DIR ]]; then
        sudo rm -rf $BCM_PROJECT_DIR
        echo "Deleted contents of '$BCM_PROJECT_DIR'." 
        echo "Note '$BCM_PROJECT_DIR' is a git repository and manages versions and history of all files."
    fi
}

CONTINUE=0
if [[ $BCM_FORCE_FLAG = 0 ]]; then
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