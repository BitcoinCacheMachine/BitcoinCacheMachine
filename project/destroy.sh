#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source ./.env

# quit if there are no BCM environment variables
if ! env | grep -q 'BCM_'; then
  echo "BCM variables not set. Please source BCM environment variables."
  exit
fi

# ensure we have an LXD project defined for this deployment
# you can use lxd projects to deploy mutliple BCM instances on the same set of hardware (i.e., lxd cluster)
if ! lxc project list | grep -q "$BCM_PROJECT_NAME"; then
  lxc project switch default
  lxc project delete "$BCM_PROJECT_NAME"
fi


if [[ $BCM_DEPLOY_TIERS = 1 ]]; then
  ./tiers/destroy.sh
fi

if [[ $BCM_DEPLOY_HOST_TEMPLATE = 1 ]]; then
  ./host_template/destroy.sh
fi