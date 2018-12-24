#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

bash -c ./rsync/destroy_lxc_rsyncd.sh

# delete container 'bcm-gateway'
bash -c "$BCM_LXD_OPS/delete_lxc_container.sh rsync rsync_template"
