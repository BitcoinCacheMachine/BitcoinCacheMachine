#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"


#./build_docker_image.sh --image-title="ots" --base-image="bcm-trezor:$BCM_VERSION"