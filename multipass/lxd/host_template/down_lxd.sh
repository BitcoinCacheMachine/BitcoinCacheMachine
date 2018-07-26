#!/bin/bash

set -e

# delete dockertemplate
if [[ $(lxc list | grep dockertemplate) ]]; then
    echo "Deleting dockertemplate lxd host."
    lxc delete --force dockertemplate
else
    echo "Skipping deletion of dockertemplate lxd host."
fi


# delete lxd profile dockertemplate_profile
if [[ $(lxc profile list | grep docker) ]]; then
    echo "Deleting docker lxd profile."
    lxc profile delete docker
else
    echo "Skipping deletion of docker lxd profile."
fi


# delete lxd profile dockertemplate_profile
if [[ $(lxc profile list | grep "dockertemplate_profile") ]]; then
    echo "Deleting dockertemplate_profile lxd profile."
    lxc profile delete dockertemplate_profile
else
    echo "Skipping deletion of dockertemplate_profile lxd profile."
fi


# delete lxd network lxdbr0
if [[ $(lxc network list | grep lxdbr0) ]]; then
    echo "Deleting network lxdbr0."
    lxc network delete lxdbr0
else
    echo "Skipping deletion of lxd network lxdbr0."
fi

# if specified, delete the template and lxd base image
if [[ $BC_HOST_TEMPLATE_DELETE = "true" ]]; then\
    if [[ $(lxc image list | grep 38219778c2cf) ]]; then
        echo "Destrying lxd image '38219778c2cf'."
        lxc image delete 38219778c2cf
    fi
fi


if [[ $(lxc storage list | grep $BC_ZFS_POOL_NAME) ]]; then
    echo "Deleting lxd storage pool $BC_ZFS_POOL_NAME."
    lxc storage rm $BC_ZFS_POOL_NAME
else
    echo "Skipping deletion of lxd xd storage pool $BC_ZFS_POOL_NAME."
fi
