#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=1091
source ./params.sh "$@"
source "$BCM_GIT_DIR/env"

if [[ $BCM_DEPLOY_STACK_KAFKA_SCHEMA_REGISTRY == 1 ]]; then
    # shellcheck disable=1091
    source ./stacks/kafkaschemareg/.env
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=$BCM_STACK_NAME"
    BCM_STACK_NAME=
fi

if [[ $BCM_DEPLOY_STACK_KAFKA_REST == 1 ]]; then
    # shellcheck disable=1091
    source ./stacks/kafkarest/.env
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=$BCM_STACK_NAME"
    BCM_STACK_NAME=
fi

if [[ $BCM_DEPLOY_STACK_KAFKA_CONNECT == 1 ]]; then
    # shellcheck disable=1091
    source ./stacks/kafkaconnect/.env
    bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=$BCM_STACK_NAME"
    BCM_STACK_NAME=
fi

# destroy the brokers and zookeeper stacks which are deployed as distinct docker services
bash -c ./broker/destroy_lxc_broker.sh
bash -c ./zookeeper/destroy_zookeeper.sh