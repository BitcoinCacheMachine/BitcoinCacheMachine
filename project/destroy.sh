#!/usr/bin/env bash

set -Eeo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1091
source ./.env

# quit if there are no BCM environment variables
if ! env | grep -q 'BCM_'; then
	echo "BCM variables not set. Please source BCM environment variables."
	exit
fi

# if the BCM_PROJECT_NAME is not set, we assume it's the one
# that our current LXD client is defaulted to.

# we assume that the user wants to delete the current project
# TODO add warning messages before executing this script.
if [[ -z $BCM_PROJECT_NAME ]]; then
	BCM_PROJECT_NAME=$(lxc project list | grep "(current)" | awk '{print $2}')
fi

export BCM_PROJECT_NAME=$BCM_PROJECT_NAME
if [[ $BCM_DEPLOY_TIERS == 1 ]]; then
	./tiers/destroy.sh --all
fi

if [[ $BCM_DEPLOY_HOST_TEMPLATE == 1 ]]; then
	./host_template/destroy.sh
fi

# ensure we have an LXD project defined for this deployment
# you can use lxd projects to deploy mutliple BCM instances on the same set of hardware (i.e., lxd cluster)
if lxc project list | grep -q "$BCM_PROJECT_NAME"; then
	lxc project switch default

	if [[ $BCM_PROJECT_NAME != "default" ]]; then
		lxc project delete "$BCM_PROJECT_NAME"
	fi
fi
