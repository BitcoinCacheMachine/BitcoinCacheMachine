#!/bin/bash

set -Eeuox pipefail

STACK_NAME=

for i in "$@"
do
case $i in
    --stack-name=*)
    STACK_NAME="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

if lxc list --format csv -c n state=RUNNING | grep -q "bcm-gateway-01"; then
    if [[ "$(lxc exec bcm-gateway-01 -- docker info --format '{{.Swarm.LocalNodeState}}')" = "active" ]]; then
        if lxc exec bcm-gateway-01 -- docker stack ls --format "{{.Name}}" | grep -q "$STACK_NAME"; then
            lxc exec bcm-gateway-01 -- docker stack rm "$STACK_NAME"
        fi
    fi
fi