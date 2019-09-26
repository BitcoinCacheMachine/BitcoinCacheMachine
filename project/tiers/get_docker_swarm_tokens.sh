#!/bin/bash

set -Eeuo pipefail

lxc exec "$BCM_MANAGER_HOST_NAME" -- wait-for-it 127.0.0.1:2377
DOCKER_SWARM_MANAGER_JOIN_TOKEN=$(lxc exec "$BCM_MANAGER_HOST_NAME" -- docker swarm join-token --quiet manager)
DOCKER_SWARM_WORKER_JOIN_TOKEN=$(lxc exec "$BCM_MANAGER_HOST_NAME" -- docker swarm join-token --quiet worker)

export DOCKER_SWARM_MANAGER_JOIN_TOKEN="$DOCKER_SWARM_MANAGER_JOIN_TOKEN"
export DOCKER_SWARM_WORKER_JOIN_TOKEN="$DOCKER_SWARM_WORKER_JOIN_TOKEN"
