#!/bin/bash

export IMAGE_NAME="bcm-ridethelightning"
export IMAGE_TAG="v0.3.0"
export TIER_NAME="bitcoin$BCM_ACTIVE_CHAIN"
export STACK_NAME="ridethelightning"
export SERVICE_NAME="ridethelightning"
export SERVICE_PORT="3000"

export STACK_DOCKER_VOLUMES="data rtlcookie"
