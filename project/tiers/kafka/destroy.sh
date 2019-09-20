#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# let's get some shared (between up/down scripts).
source ./env

source ./stacks/kafkaconnect/env
bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=$STACK_NAME"
STACK_NAME=

# shellcheck disable=1091
source ./stacks/kafkarest/env
bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=$STACK_NAME"
STACK_NAME=

# shellcheck disable=1091
source ./stacks/kafkaschemareg/env
bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=$STACK_NAME"
STACK_NAME=

# destroy the brokers and zookeeper stacks which are deployed as distinct docker services
bash -c ./broker/destroy_lxc_broker.sh
bash -c ./zookeeper/destroy.sh

# now remove the tier.
bash -c "$BCM_GIT_DIR/project/tiers/remove_tier.sh --tier-name=kafka"
