#!/bin/bash

if lxc list | grep -q "bcm-gateway-01"; then
    if [[ "$(lxc exec bcm-gateway-01 -- docker info --format '{{.Swarm.LocalNodeState}}')" = "active" ]]; then
        if lxc exec bcm-gateway-01 -- docker stack ls | grep -q "schemaregistry"; then
            lxc exec bcm-gateway-01 -- docker stack rm schemaregistry
            sleep 5
        fi
    fi
fi