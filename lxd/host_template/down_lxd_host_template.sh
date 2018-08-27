#!/bin/bash

set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"


# delete dockertemplate
if [[ $(lxc list | grep dockertemplate) ]]; then
    echo "Deleting dockertemplate lxd host."
    lxc delete --force dockertemplate
fi


# destroy the lxc profiles
bash -c ./delete_lxd_profiles.sh


# bcm-template
if [[ $BCM_LXD_DOCKER_TEMPLATE_IMAGE_DELETE = "true" ]]; then
  if [[ $(lxc image list | grep bcm-template) ]]; then
    echo "Destrying lxd image 'bcm-template'."
    lxc image delete "bcm-template"
  fi
fi

# if specified, delete the template and lxd base image
if [[ $BCM_HOST_TEMPLATE_BCM_BIONIC_BASE_DELETE = "true" ]]; then
  if [[ $(lxc image list | grep bcm-bionic-base) ]]; then
      echo "Destrying lxd image 'bcm-bionic-base'."
      lxc image delete "bcm-bionic-base"
  fi
fi

if [[ $BCM_HOST_TEMPLATE_ZFS_BCM_DATA_DELETE = "true" ]]; then
  # delete lxd storage pool 
  if [[ $(lxc storage list | grep "bcm_data" | grep "| 0") ]]; then
    echo "Deleting lxd storage pool 'bcm_data'."
    lxc storage delete "bcm_data"
  else
    echo "LXC storage pool 'bcm_data' can't be deleted."
  fi
fi