#!/bin/bash

# stop scrtip if error is encountered.
set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# Source the LXD environment variables maintained by the user in ~/.bcm/lxd.env.sh
source ~/.bcm/lxd.env.sh

# get or update the BCM host template git repo
if [[ $BC_INSTALLATION_PATH = "bcm" ]]; then
  echo "Calling Bitcoin Cache Machine destruction script."
  
  export BC_ZFS_POOL_NAME="bcm_data"

  bash -c ./bcm/down_lxd.sh
elif [[ $BC_INSTALLATION_PATH = "bcs" ]]; then
  echo "Calling Bitcoin Cache Stack destruction script."

  export BC_ZFS_POOL_NAME="bcs_data"

  bash -c ./bcs/down_lxd.sh
fi



# delete the host template if configured
if [[ $BC_HOST_TEMPLATE_DELETE = 'true' ]]; then
  echo "Destrying host template"
  bash -c ./host_template/down_lxd.sh
else
  if [[ $(lxc image list | grep bctemplate) ]]; then
    echo "Keeping the lxd host template."
  fi
fi



# bctemplate
if [[ $BC_LXD_IMAGE_BCTEMPLATE_DELETE = 'true' ]]; then
  if [[ $(lxc image list | grep bctemplate) ]]; then
    echo "Destrying lxd image 'bctemplate'."
    lxc image delete bctemplate
  fi
fi