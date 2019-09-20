#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1091
source ./env

if [[ $BCM_DEPLOY_STACK_CONNECTUI == 1 ]]; then
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=connectui"
fi

if [[ $BCM_DEPLOY_STACK_SCHEMAREGUI == 1 ]]; then
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=schemaregistryui"
fi

if [[ $BCM_DEPLOY_STACK_KAFKATOPICSUI == 1 ]]; then
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=kafkatopicsui"
fi

if [[ $BCM_DEPLOY_STACK_KAFKACONTROLCENTER == 1 ]]; then
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=kafkacontrolcenter"
fi

bash -c "$BCM_GIT_DIR/project/tiers/remove_tier.sh --tier-name=underlay"

bash -c "$BCM_LXD_OPS/delete_lxc_network.sh --network-name=bcmLocalnet"
