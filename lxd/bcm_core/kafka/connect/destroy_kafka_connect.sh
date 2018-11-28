#!/bin/bash

set -Eeuo pipefail

bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=kafkaconnect"