#!/bin/bash

lxc exec bcm-gateway -- docker stack rm regmirror

rm -rf ~/.bcm/runtime/$(lxc remote get-default)/$BCM_LXC_GATEWAY_CONTAINER_NAME/registry_mirror/