#!/bin/bash

set -e

export TIER_NAME="bitcoin$BCM_ACTIVE_CHAIN"
export STACK_NAME="torproxy"
export SERVICE_NAME="torproxy"

export STACK_DOCKER_VOLUMES="data"
