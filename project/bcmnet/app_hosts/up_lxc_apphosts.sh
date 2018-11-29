#!/bin/bash

# exit script if there's an error anywhere
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

if [[ $BCM_ADMIN_RSYNC_INSTALL = "true" ]]; then
  echo "Deploying lxc host 'rsyncd' and deploying the associated rsync stack."
  bash -c "./rsync/up_lxc_rsyncd.sh"
fi
