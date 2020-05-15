#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# let's remove everything bcm related;
./uninstall.sh --storage --cache --lxd
# --storage
# --cache
# --lxd

# install bcm
./install.sh

# then deploy
#bcm deploy
