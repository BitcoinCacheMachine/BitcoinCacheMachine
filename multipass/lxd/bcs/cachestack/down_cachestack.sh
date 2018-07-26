#!/bin/bash

set -e

# delete lxd container cachestack
if [[ $(lxc list | grep cachestack) ]]; then
    echo "Deleting lxd container 'cachestack'."
    lxc delete --force cachestack >/dev/null
else
    echo "Skipping deletion of lxd container 'cachestack'."
fi


# delete lxd container cachestack
if [[ $(lxc profile list | grep cachestackprofile) ]]; then
    echo "Deleting lxd profile 'cachestackprofile'."
    lxc profile delete cachestackprofile >/dev/null
else
    echo "Skipping deletion of lxd profile 'cachestackprofile'."
fi


# delete lxd network lxdbrCacheStack 
if [[ $(lxc network list | grep lxdbrCacheStack) ]]; then
    echo "Deleting lxd network 'lxdbrCacheStack'."
    lxc network delete lxdbrCacheStack
else
    echo "Skipping deletion of lxd network lxdbrCacheStack."
fi

# delete lxd network lxdBCSMgrnet 
if [[ $(lxc network list | grep lxdBCSMgrnet) ]]; then
    echo "Deleting lxd network 'lxdBCSMgrnet'."
    lxc network delete lxdBCSMgrnet
else
    echo "Skipping deletion of lxd network lxdBCSMgrnet."
fi

# delete lxd storage cachestack-dockervol 
if [[ $(lxc storage list | grep "cachestack-dockervol") ]]; then
    echo "Deleting lxd storage pool 'cachestack-dockervol'."
    lxc storage delete cachestack-dockervol
else
    echo "Skipping deletion of lxd stroage pool cachestack-dockervol."
fi
