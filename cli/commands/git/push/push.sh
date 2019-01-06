#!/bin/bash

# BCM_GIT_COMMIT_MESSAGE must be set.
if [[ -z $BCM_GIT_REPO_DIR ]]; then
	echo "BCM_GIT_REPO_DIR is not set. Exiting"
	exit
fi

if docker ps -a | grep -q "bcm-trezor-gitter"; then
	docker system prune -f
fi

# BCM_PROJECT_DIR must be set. This is our public key material.
if [[ -z $BCM_PROJECT_DIR ]]; then
	echo "BCM_PROJECT_DIR is not set. Exiting"
	exit
else
	if [[ ! -d $BCM_PROJECT_DIR ]]; then
		echo "'$BCM_PROJECT_DIR' does not exist. Exiting."
		exit
	fi
fi

docker run -d --name bcm-tor-ssh-gitpusher \
	-v "$BCM_PROJECT_DIR":/root/.gnupg \
	-v "$BCM_GIT_REPO_DIR":/gitrepo \
	--device="$BCM_TREZOR_USB_PATH" \
	bcm-trezor:latest

docker exec -it \
	-e BCM_GIT_CLIENT_USERNAME="$BCM_GIT_CLIENT_USERNAME"

bcm-tor-ssh-gitpusher bash -c /bcm_scripts/git_push.sh

docker kill bcm-tor-ssh-gitpusher
docker system prune -f
