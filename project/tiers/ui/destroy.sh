#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1091
source ./.env

if [[ $BCM_DEPLOY_STACK_CONNECTUI = 1 ]]; then
    bash -c ./stacks/connect_ui/destroy_connect_ui.sh
fi

if [[ $BCM_DEPLOY_STACK_SCHEMAREGUI = 1 ]]; then
    bash -c ./stacks/schema_registry_ui/destroy_schema_registry_ui.sh
fi

if [[ $BCM_DEPLOY_STACK_KAFKATOPICSUI = 1 ]]; then
    bash -c ./stacks/topics_ui/destroy_topics_ui.sh
fi

if [[ $BCM_DEPLOY_STACK_KAFKACONTROLCENTER = 1 ]]; then
    bash -c ./stacks/control_center/destroy_control_center.sh
fi