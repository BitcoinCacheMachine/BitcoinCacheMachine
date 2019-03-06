#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# don't even think about proceeding unless the gateway BCM tier is up and running.
if bcm tier list | grep -q ui; then
    echo "The 'ui' tier is already provisioned."
    exit
fi


# don't even think about proceeding unless the gateway BCM tier is up and running.
if ! bcm tier list | grep -q kafka; then
    bcm tier create kafka
fi

# Let's provision the system containers to the cluster.
bash -c "$BCM_LXD_OPS/create_tier.sh --tier-name=ui"


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

