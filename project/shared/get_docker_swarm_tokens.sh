#!/bin/bash

set -Eeuo pipefail

lxc exec "$BCM_GATEWAY_HOST_NAME" -- wait-for-it 127.0.0.1:2377
DOCKER_SWARM_MANAGER_JOIN_TOKEN=$(lxc exec "$BCM_GATEWAY_HOST_NAME" -- docker swarm join-token manager | grep token | awk '{ print $5 }')
DOCKER_SWARM_WORKER_JOIN_TOKEN=$(lxc exec "$BCM_GATEWAY_HOST_NAME" -- docker swarm join-token worker | grep token | awk '{ print $5 }')

export DOCKER_SWARM_MANAGER_JOIN_TOKEN="$DOCKER_SWARM_MANAGER_JOIN_TOKEN"
export DOCKER_SWARM_WORKER_JOIN_TOKEN="$DOCKER_SWARM_WORKER_JOIN_TOKEN"
