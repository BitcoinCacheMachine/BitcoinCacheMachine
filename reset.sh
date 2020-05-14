#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

bash -c "./uninstall.sh --storage"
# --storage
# --cache
# --lxd

sudo bash -c ./install.sh