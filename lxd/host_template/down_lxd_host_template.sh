#!/bin/bash

set -e

# delete dockertemplate
if [[ $(lxc list | grep dockertemplate) ]]; then
    echo "Deleting dockertemplate lxd host."
    lxc delete --force dockertemplate
fi


# bctemplate
if [[ $BC_LXD_IMAGE_BCTEMPLATE_DELETE = 'true' ]]; then
  if [[ $(lxc image list | grep bctemplate) ]]; then
    echo "Destrying lxd image 'bctemplate'."
    lxc image delete bctemplate
  fi
fi


# delete lxd storage pool 
if [[ $BCM_ZFS_STORAGE_POOL_DELETE = "true" ]]; then
    # make sure it exists
    if [[ $(lxc storage list | grep "bcm_data") ]]; then
        # make sure it's unused
        if [[ ! -z $(lxc storage list | grep "bcm_data" | grep "| 0") ]]; then
            echo "Deleting lxd storage pool 'bcm_data'."
            lxc storage delete bcm_data
        else
            echo "Keeping lxc storage pool bcm_data."
        fi
    fi
fi


# if specified, delete the template and lxd base image
if [[ $BCM_HOST_TEMPLATE_DELETE = "true" ]]; then\
    if [[ $(lxc image list | grep 38219778c2cf) ]]; then
        echo "Destrying lxd image '38219778c2cf'."
        lxc image delete 38219778c2cf
    fi
fi



# delete lxd profile dockertemplate_profile
if [[ $(lxc profile list | grep "docker ") ]] ; then
  # make sure it doesn't have anything attached to it.
  if [[ ! -z $(lxc profile list | grep docker | grep "| 0") ]]; then
    echo "Deleting docker lxd profile."
    lxc profile delete docker
  else
    echo "Could not delete lxd profile 'docker' due to attached resources. Check your BCM environment variables."
  fi
fi



# delete lxd profile dockertemplate_profile
if [[ $(lxc profile list | grep "dockertemplate_profile") ]] ; then
  # make sure it doesn't have anything attached to it.
  if [[ ! -z $(lxc profile list | grep docker | grep "| 0") ]]; then
    echo "Deleting dockertemplate_profile lxd profile."
    lxc profile delete dockertemplate_profile
  else
    echo "Could not delete lxd profile 'dockertemplate_profile' due to attached resources. Check your BCM environment variables."
  fi
fi
