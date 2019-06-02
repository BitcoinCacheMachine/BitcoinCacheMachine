#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# this script destroys any images that were build under the BCM_GIT_DIR/controller directory
function removeDockerImage {
    IMAGE_NAME="$1"
    if docker image list --format "{{.Repository}},{{.Tag}}" | grep -q "bcm-$IMAGE_NAME,$BCM_VERSION"; then
        docker image rm "bcm-$IMAGE_NAME:$BCM_VERSION"
    fi
}

removeDockerImage ots
removeDockerImage gpgagent
removeDockerImage trezor
