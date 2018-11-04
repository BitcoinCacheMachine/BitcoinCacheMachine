#!/usr/bin/env bash

#### this is what we do when we are told to attach an underlay or stay on virtual network
if [[ $BCM_BCMNETTEMPLATE_MACVLAN_TO_UNDERLAY = "true" ]]; then
    # then update the profile with the user-specified interface
    echo "Setting lxc profile 'bcm-bcmnet_template-profile' eth0 to host interface '$BCM_BCMNETTEMPLATE_MACVLAN_INTERFACE'."
    lxc profile device set bcm-bcmnet_template-profile eth0 type nic
    lxc profile device set bcm-bcmnet_template-profile eth0 nictype macvlan
    lxc profile device set bcm-bcmnet_template-profile eth0 parent $BCM_BCMNETTEMPLATE_MACVLAN_INTERFACE
else
    echo "BCM directed to perform a standalone deployment. LXC container '$BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME' will not macvlan any interface; it connects to a bcm-gateway via a LXC local network bridge."
fi
