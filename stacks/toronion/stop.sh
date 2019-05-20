#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# this gets called to clean up anything stack specific. In this case, we run bcm ssh remove-onion
bcm ssh remove-onion --title="$(lxc remote get-default)-$BCM_ACTIVE_CHAIN"
