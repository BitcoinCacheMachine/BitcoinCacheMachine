#!/bin/bash

# quit if error.
set -e

# delete lxd container manager1
if [[ $(lxc list | grep manager1) ]]; then
    echo "Destroying lxd container 'manager1'."
    lxc delete --force manager1
else
    echo "LXC container 'manager1' not found. Skipping."
fi


# delete lxd network managernet
if [[ $(lxc network list | grep managernet) ]]; then
    echo "Destroying lxd network 'managernet'."
    lxc network delete managernet
else
    echo "LXD network 'managernet' not found. Skipping."
fi

# delete lxd network managernet
if [[ $(lxc network list | grep lxdbrManager1) ]]; then
    echo "Destroying lxd network 'lxdbrManager1'."
    lxc network delete lxdbrManager1
else
    echo "LXD network 'lxdbrManager1' not found. Skipping."
fi

if [[ $BCM_MANAGER1_DELETE_DOCKERVOL = "true" ]]; then
    # delete lxd storage pool manager1-dockervol
    if [[ $(lxc storage list | grep "manager1-dockervol") ]]; then
        echo "Destroying lxd network 'managernet'."
        lxc storage delete manager1-dockervol
    fi
fi

# delete lxd profile manager1 
if [[ $(lxc profile list | grep manager1) ]]; then
    echo "Destroying lxd profile 'manager1'."
    lxc profile delete manager1
else
    echo "LXC profile 'manager1' not found. Skipping."
fi



# delete lxd profile manager-template 
if [[ $(lxc list | grep "manager-template") ]]; then
    echo "Destroying lxd container 'manager-template'."
    lxc delete --force manager-template
else
    echo "LXC profile 'manager-template' not found. Skipping."
fi
