#!/bin/bash

if [[ $BCM_GATEWAY_CONTAINER_DELETE = "true" ]]; then
    # delete lxd container bcm-gateway
    if [[ -n "$(lxc list -c n | grep bcm-gateway)" ]] ; then
        echo "Deleting lxd container 'bcm-gateway'."
        lxc delete --force bcm-gateway
    fi
fi


if [[ $BCM_GATEWAY_TEMPLATE_DELETE = "true" ]]; then
    if [[ $(lxc list | grep "gateway-template") ]]; then
        # delete lxd container gateway-template
        if [[ $(lxc info gateway-template | grep "Name: gateway-template") ]]; then
            echo "Deleting lxd container 'gateway-template'."
            lxc delete --force gateway-template
        fi
    fi
fi
