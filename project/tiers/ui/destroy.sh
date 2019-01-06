#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=1090
source "$BCM_GIT_DIR/.env"

# shellcheck disable=1091
source ./.env

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
