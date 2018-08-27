#!/bin/bash

# delete lxd container gateway
if [[ $(lxc profile list | grep gatewayprofile) ]]; then
    echo "Deleting lxd profile 'gatewayprofile'."
    lxc profile delete gatewayprofile >/dev/null
fi