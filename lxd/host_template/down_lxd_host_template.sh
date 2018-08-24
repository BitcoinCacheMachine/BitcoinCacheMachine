#!/bin/bash

set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"


# delete dockertemplate
if [[ $(lxc list | grep dockertemplate) ]]; then
    echo "Deleting dockertemplate lxd host."
    lxc delete --force dockertemplate
fi


# bctemplate
if [[ $BCM_LXD_IMAGE_BCTEMPLATE_DELETE = "true" ]]; then
  if [[ $(lxc image list | grep bctemplate) ]]; then
    echo "Destrying lxd image 'bctemplate'."
    lxc image delete bctemplate
  fi
fi

# destroy the lxc profiles
bash -c ./down_lxd_profiles.sh


# delete lxd storage pool 
if [[ $BCM_ZFS_STORAGE_POOL_DELETE = "true" ]]; then
  # if specified, delete the template and lxd base image
  if [[ $BCM_HOST_TEMPLATE_DELETE = "true" ]]; then
    if [[ $(lxc image list | grep bbb592c417b6) ]]; then
        echo "Destrying lxd image 'bbb592c417b6'."
        lxc image delete bbb592c417b6
    fi
  fi
  
  # make sure it exists
  if [[ $(lxc storage list | grep "bcm_data") ]]; then
    echo "Deleting lxd storage pool 'bcm_data'."
    lxc storage delete "bcm_data"
  fi
fi

