#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# let's remove everything bcm related;
./uninstall.sh --all
# --storage
# --cache
# --lxd

# we need to source our potentially new ~/.bashrc before calling ./install.
source "$HOME/.bashrc"


# install bcm
./install.sh

# then deploy
bcm deploy
