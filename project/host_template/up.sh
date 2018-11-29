#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")"

echo "Starting 'up_lxc_host_template.sh'."

BCM_REBUILD_TEMPLATE=0
# first, let's check to see if our end proudct -- namely our LXC image with alias 'bcm-template'
# if it exists, we will quit by default, UNLESS the user has passed in an override, in which case
# it (being the lxc image 'bcm-template') will be rebuilt.
if lxc image list --format csv | grep -q "bcm-template"; then
  if $BCM_REBUILD_TEMPLATE -eq 1; then
    echo "TODO: implement rebuild logic"
  else
    echo "LXC image bcm-template exists and BCM_REBUILD_TEMPLATE was not set. The existing image will not be modified."
    exit
  fi
fi

# download the main ubuntu image if it doesn't exist.
# if it does exist, it SHOULD be the latest image (due to auto-update).
if ! lxc image list --format csv | grep -q "bcm-lxc-base"; then
  echo "Copying the ubuntu/cosmic lxc image from the public 'image:' server to '$(lxc remote get-default):bcm-lxc-base'"
  lxc image copy images:ubuntu/cosmic "$(lxc remote get-default):" --alias bcm-lxc-base --auto-update
fi

function createProfile {
    PROFILE_NAME=$1

    # create the profile if it doesn't exist.
    if ! lxc profile list | grep -q "$PROFILE_NAME"; then
        lxc profile create "$PROFILE_NAME"
    fi

    echo "Applying $PROFILE_NAME to lxc profile '$PROFILE_NAME'."
    lxc profile edit "$PROFILE_NAME" < "./lxd_profiles/$PROFILE_NAME.yml"
}

if lxc profile list | grep -q "bcm_default"; then
  createProfile bcm_default
fi

# create the docker_unprivileged profile
createProfile docker_unprivileged

# create the docker_privileged profile
createProfile docker_privileged

./create_lxc_host_template.sh