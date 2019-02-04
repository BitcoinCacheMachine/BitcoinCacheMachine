#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

sudo docker build -t bcm-trezor:latest .
sudo docker build -t bcm-gpgagent:latest ./gpgagent/
