#!/bin/bash

set -Eeuo pipefail

bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/remove_docker_stack.sh --stack-name=schemaregistry"