#!/bin/bash

# BCM_GIT_COMMIT_MESSAGE must be set.
if [[ -z $BCM_GIT_REPO_DIR ]]; then
    echo "BCM_GIT_REPO_DIR is not set. Exiting"
    exit
fi

if sudo docker ps -a | grep -q "bcm-trezor-gitter"; then
    sudo docker system prune -f
fi

sudo docker run -d --name bcm-tor-ssh-gitpusher \
-v "$BCM_PROJECT_DIR":/root/.gnupg \
-v "$BCM_GIT_REPO_DIR":/gitrepo \
--device="$BCM_TREZOR_USB_PATH" \
bcm-trezor:latest

sudo docker exec -it \
-e BCM_GIT_CLIENT_USERNAME="$BCM_GIT_CLIENT_USERNAME"

bcm-tor-ssh-gitpusher bash -c /bcm_scripts/git_push.sh

sudo docker kill bcm-tor-ssh-gitpusher
sudo docker system prune -f