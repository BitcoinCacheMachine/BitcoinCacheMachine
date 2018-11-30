#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")" 

source ./tier.env

# bring up the docker UI STACKS.
# TODO eventually we'll hide these behind a VPN gateway (so you first have to VPN eg wireguard)
# into your data center BEFORE being able to access these services. This could be implemented
# from a docker container.

if [[ $BCM_DEPLOY_STACK_CONNECTUI = 1 ]]; then
    bash -c ./stacks/connect_ui/up_connect_ui.sh
fi

if [[ $BCM_DEPLOY_STACK_SCHEMAREGUI = 1 ]]; then
    bash -c ./stacks/schema_registry_ui/up_schema_registry_ui.sh
fi

if [[ $BCM_DEPLOY_STACK_KAFKATOPICSUI = 1 ]]; then
    bash -c ./stacks/topics_ui/up_topics_ui.sh
fi

if [[ $BCM_DEPLOY_STACK_KAFKACONTROLCENTER = 1 ]]; then
    bash -c ./stacks/control_center/up_control_center.sh
fi