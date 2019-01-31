#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=1090
source "$BCM_GIT_DIR/env"

# shellcheck disable=1091
source ./env

if [[ $BCM_DEPLOY_STACK_CONNECTUI == 1 ]]; then
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --env-file-path=$(readlink -f ./stacks/connectui/.env)"
fi

if [[ $BCM_DEPLOY_STACK_SCHEMAREGUI == 1 ]]; then
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --env-file-path=$(readlink -f ./stacks/schemaregistryui/.env)"
fi

if [[ $BCM_DEPLOY_STACK_KAFKATOPICSUI == 1 ]]; then
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --env-file-path=$(readlink -f ./stacks/kafkatopicsui/.env)"
fi

if [[ $BCM_DEPLOY_STACK_KAFKACONTROLCENTER == 1 ]]; then
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --env-file-path=$(readlink -f ./stacks/kafkacontrolcenter/.env)"
fi