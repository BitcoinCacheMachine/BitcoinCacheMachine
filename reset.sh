#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# let's remove everything bcm related;
bash -c "./uninstall.sh --storage --pass"
# --storage
# --cache
# --lxd

# install bcm
bash -c ./install.sh

# then deploy
bcm deploy
