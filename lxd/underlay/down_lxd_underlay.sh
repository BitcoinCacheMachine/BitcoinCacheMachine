#!/bin/bash

# exit script if there's an error anywhere
set -e

echo "Starting ./down_lxd_underlay.sh'."

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# get the current directory where this script is so we can reference it later.
SCRIPT_DIR=$(pwd)

lxc list >>/dev/null

# delete lxd container underlay
if [[ $(lxc list | grep underlay) ]]; then
    echo "Deleting lxd container 'underlay'."
    lxc delete --force underlay >/dev/null
fi


# delete lxd container underlay
if [[ $(lxc profile list | grep underlayprofile) ]]; then
    echo "Deleting lxd profile 'underlayprofile'."
    lxc profile delete underlayprofile >/dev/null
fi


# delete lxd network lxdbrUnderlay 
if [[ $(lxc network list | grep lxdbrUnderlay) ]]; then
    echo "Deleting lxd network 'lxdbrUnderlay'."
    lxc network delete lxdbrUnderlay
fi


# delete lxd network lxdBCSMgrnet 
if [[ $(lxc network list | grep lxdBCSMgrnet) ]]; then
    echo "Deleting lxd network 'lxdBCSMgrnet'."
    lxc network delete lxdBCSMgrnet
fi

# delete lxd network lxdBrNowhere 
if [[ $(lxc network list | grep lxdBrNowhere) ]]; then
    echo "Deleting lxd network 'lxdBrNowhere'."
    lxc network delete lxdBrNowhere
fi

# if the user has instructed us to delete the dockervol backing.
if [[ $BCS_DELETE_DOCKERVOL = "true" ]]; then
    # delete lxd storage underlay-dockervol 
    if [[ $(lxc storage list | grep "underlay-dockervol") ]]; then
        echo "Deleting lxd storage pool 'underlay-dockervol'."
        lxc storage delete underlay-dockervol
    fi
fi

# delete the host template if configured
if [[ $BC_HOST_TEMPLATE_DELETE = 'true' ]]; then
  echo "Destrying host template"
  bash -c ../shared/host_template/down_lxd.sh
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
