#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

docker build -t bcm-trezor:latest .
docker build -t bcm-gpgagent:latest ./gpgagent/
