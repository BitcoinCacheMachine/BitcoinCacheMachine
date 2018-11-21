#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# quit if there are no BCM environment variables
if ! env | grep -q 'BCM_'; then
  echo "BCM variables not set. Please source BCM environment variables."
  exit
fi

echo "Calling ./bcm_core/destroy_lxc_core.sh"
./bcm_core/destroy_lxc_core.sh

# ensure we have an LXD project defined for this deployment
# you can use lxd projects to deploy mutliple BCM instances on the same set of hardware (i.e., lxd cluster)
if ! lxc project list | grep -q "$BCM_PROJECT_NAME"; then
  lxc project switch default
  lxc project delete "$BCM_PROJECT_NAME"
fi
