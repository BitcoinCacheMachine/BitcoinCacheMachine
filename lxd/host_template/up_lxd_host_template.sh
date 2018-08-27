#!/bin/bash

set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# create lxdbr0 if it doesn't exist.
if [[ -z $(lxc network list | grep lxdbr0) ]]; then
  lxc network create lxdbr0
fi

bash -c ./create_lxd_storage_bcm-data.sh

bash -c ./get_lxd_bcm-bionic-base.sh

bash -c ./up_lxd_profiles.sh

bash -c ./create_lxd_host_template.sh