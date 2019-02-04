#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"


# if there's an issue resolving archive.ubuntu.com, follow these steps:
#https://development.robinwinslow.uk/2016/06/23/fix-docker-networking-dns/#the-permanent-system-wide-fix

sudo docker build -t bcm-trezor:latest .
sudo docker build -t bcm-gpgagent:latest ./gpgagent/
