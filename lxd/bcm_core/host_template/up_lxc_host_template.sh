#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")"
source ./defaults.sh

echo "Starting 'up_lxc_host_template.sh'."

# download the main ubuntu image if it doesn't exist.
# if it does exist, it SHOULD be the latest image (due to auto-update).
if [[ ! $(lxc image list | grep "bcm-lxc-base") ]]; then
  echo "Copying the ubuntu/cosmic lxc image from the public 'image:' server to '$(lxc remote get-default):bcm-lxc-base'"
  lxc image copy images:ubuntu/cosmic $(lxc remote get-default): --alias bcm-lxc-base --auto-update
fi

function createProfile {
  PROFILE_NAME=$1

  # create the $2 profile if it doesn't exist.
  if [[ -z $(lxc profile list | grep $PROFILE_NAME) ]]; then
      lxc profile create $PROFILE_NAME
  fi

  echo "Applying $PROFILE_NAME to lxc profile '$PROFILE_NAME'."
  cat ./lxd_profiles/$PROFILE_NAME.yml | lxc profile edit $PROFILE_NAME
}

if [[ $(lxc profile list | grep "bcm_default" ) ]]; then
  createProfile bcm_default
fi

# create the docker_unprivileged profile
createProfile docker_unprivileged

# create the docker_privileged profile
createProfile docker_privileged

./create_lxc_host_template.sh