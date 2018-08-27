#!/bin/bash

set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# call bcm_script_before.sh to perform the things that every BCM script must do prior to proceeding
bash -c $BCM_LOCAL_GIT_REPO/resources/bcm/bcm_script_before.sh

# get the current directory where this script is so we can reference it later.
SCRIPT_DIR=$(pwd)

bash -c ./down_lxd_gateway_containers.sh

bash -c ./down_lxd_gateway_profiles.sh

bash -c ./down_lxd_gateway_networks.sh

bash -c ./down_lxd_gateway_storage.sh