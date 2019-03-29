#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"


# if there's an issue resolving archive.ubuntu.com, follow these steps:
#https://development.robinwinslow.uk/2016/06/23/fix-docker-networking-dns/#the-permanent-system-wide-fix

docker build -t "bcm-trezor:$BCM_VERSION" .
docker build -t "bcm-gpgagent:$BCM_VERSION" ./gpgagent/
