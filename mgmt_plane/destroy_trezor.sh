#!/bin/bash

set -e

while getopts n:e: option
do
    case "${option}"
    in
    n) export BCM_CURRENT_PROJECT_NAME=${OPTARG};;
    esac
done


if [[ -z $BCM_CURRENT_PROJECT_NAME ]]; then
  echo "BCM_CURRENT_PROJECT_NAME not set. Use '-n <bcmprojectname>''."
  exit
fi

source $BCM_LOCAL_GIT_REPO_DIR/resources/export_bcm_envs.sh

sudo rm -Rf $BCM_RUNTIME_DIR/projects/$BCM_CURRENT_PROJECT_NAME

if [[ ! -z $(snap list | grep docker) ]]; then
    if [[ ! -z $(docker ps -a | grep trezorgpg) ]]; then
        docker kill trezorgpg
    fi

    docker system prune -f
fi

# unset the BCM_CURRENT_PROJECT_NAME var.
export BCM_CURRENT_PROJECT_NAME=""


docker image rm bcm-trezor:latest