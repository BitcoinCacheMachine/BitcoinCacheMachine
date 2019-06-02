#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"


function buildDockerImage {
    IMAGE_NAME="$1"
    if ! docker image list --format "{{.Repository}},{{.Tag}}" | grep -q "bcm-$IMAGE_NAME,$BCM_VERSION"; then
        docker build --build-arg BCM_DOCKER_BASE_TAG="$BCM_DOCKER_BASE_TAG" --build-arg BCM_VERSION="$BCM_VERSION" -t "bcm-$IMAGE_NAME:$BCM_VERSION" "./$IMAGE_NAME/"
    fi
}

buildDockerImage trezor
buildDockerImage gpgagent
buildDockerImage ots
