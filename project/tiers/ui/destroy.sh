#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1090
source "$BCM_GIT_DIR/.env"
source ./.env

# iterate over endpoints and delete relevant resources
for endpoint in $(bcm cluster list --endpoints); do
    #echo $endpoint
    HOST_ENDING=$(echo "$endpoint" | tail -c 2)
    ZOOKEEPER_STACK_NAME="zookeeper-$(printf %02d "$HOST_ENDING")"
    
    # remove swarm services related to kafka
    bash -c "$BCM_GIT_DIR/project/shared/remove_docker_stack.sh --stack-name=$ZOOKEEPER_STACK_NAME"
done

# remove the network
if lxc list | grep -q "bcm-gateway-01"; then
    if lxc exec bcm-gateway-01 -- docker network ls | grep -q zookeepernet; then
        lxc exec bcm-gateway-01 -- docker network remove zookeepernet
    fi
    
fi

if [[ $BCM_DEPLOY_STACK_CONNECTUI == 1 ]]; then
    # shellcheck disable=SC1091
    source ./stacks/topics_ui/.env
    bash -c "$BCM_GIT_DIR/project/shared/remove_docker_stack.sh --stack-name=$BCM_STACK_NAME"
    BCM_STACK_NAME=
fi

if [[ $BCM_DEPLOY_STACK_SCHEMAREGUI == 1 ]]; then
    # shellcheck disable=1091
    source ./stacks/control_center/.env
    bash -c "$BCM_GIT_DIR/project/shared/remove_docker_stack.sh --stack-name=$BCM_STACK_NAME"
    BCM_STACK_NAME=
fi


if [[ $BCM_DEPLOY_STACK_KAFKATOPICSUI == 1 ]]; then
    # shellcheck disable=1091
    source ./stacks/control_center/.env
    bash -c "$BCM_GIT_DIR/project/shared/remove_docker_stack.sh --stack-name=$BCM_STACK_NAME"
    BCM_STACK_NAME=
fi



if [[ $BCM_DEPLOY_STACK_KAFKACONTROLCENTER == 1 ]]; then
    # shellcheck disable=1091
    source ./stacks/control_center/.env
    bash -c "$BCM_GIT_DIR/project/shared/remove_docker_stack.sh --stack-name=$BCM_STACK_NAME"
    BCM_STACK_NAME=
fi
