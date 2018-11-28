#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

./tiers/destroy_bcm_core_tiers.sh

./host_template/destroy_lxc_host_template.sh
