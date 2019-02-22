#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1091
source ./env

# bring up the docker UI STACKS.
# TODO eventually we'll hide these behind a VPN gateway (so you first have to VPN eg wireguard)
# into your data center BEFORE being able to access these services. This could be implemented
# from a docker container.

if [[ $BCM_DEPLOY_STACK_CONNECTUI == 1 ]]; then
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/connectui/env"
fi

if [[ $BCM_DEPLOY_STACK_SCHEMAREGUI == 1 ]]; then
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/schemaregistryui/env"
fi

if [[ $BCM_DEPLOY_STACK_KAFKATOPICSUI == 1 ]]; then
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/kafkatopicsui/env"
fi

if [[ $BCM_DEPLOY_STACK_KAFKACONTROLCENTER == 1 ]]; then
    bash -c "$BCM_LXD_OPS/deploy_stack_init.sh --env-file-path=$(pwd)/stacks/kafkacontrolcenter/env"
fi
