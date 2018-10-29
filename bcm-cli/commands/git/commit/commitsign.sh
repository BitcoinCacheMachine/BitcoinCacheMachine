#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# BCM_GIT_COMMIT_MESSAGE must be set.
if [[ -z $BCM_GIT_COMMIT_MESSAGE ]]; then
    echo "BCM_GIT_COMMIT_MESSAGE is not set. Exiting"
    exit
fi

# BCM_GIT_COMMIT_MESSAGE must be set.
if [[ -z $BCM_GIT_REPO_DIR ]]; then
    echo "BCM_GIT_REPO_DIR is not set. Exiting"
    exit
fi

# BCM_GIT_COMMIT_MESSAGE must be set.
if [[ -z $BCM_EMAIL_ADDRESS ]]; then
    echo "BCM_EMAIL_ADDRESS is not set. Exiting"
    exit
fi

bash -c "$BCM_LOCAL_GIT_REPO/trezor/build.sh"


if [[ ! -z $(docker ps -a | grep "bcm-trezor-gitter") ]]; then
    #docker kill bcm-trezor-gitter
    docker system prune -f
fi

# BCM_GIT_COMMIT_MESSAGE must be set.
if [[ -z $BCM_PROJECT_DIR ]]; then
    echo "BCM_PROJECT_DIR is not set. Exiting"
    exit
else
    if [[ ! -d $BCM_PROJECT_DIR ]]; then
        echo "'$BCM_PROJECT_DIR' does not exist. Exiting."
        exit
    fi
fi

docker run -d --name bcm-trezor-gitter \
    -v $BCM_PROJECT_DIR:/root/.gnupg \
    -v $BCM_GIT_REPO_DIR:/gitrepo \
    --device="$BCM_TREZOR_USB_PATH" \
    bcm-trezor:latest

docker exec -it \
    -e BCM_GIT_CLIENT_USERNAME="$BCM_GIT_CLIENT_USERNAME" \
    -e BCM_EMAIL_ADDRESS="$BCM_EMAIL_ADDRESS" \
    -e BCM_GIT_COMMIT_MESSAGE="$BCM_GIT_COMMIT_MESSAGE" \
    bcm-trezor-gitter bash -c /bcm_scripts/commit_sign_git_repo.sh

# docker kill bcm-trezor-gitter
# docker system prune -f
