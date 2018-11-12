#!/usr/bin/env bash

set -eu
cd "$(dirname "$0")"
source ./defaults.sh

#now create the actual runtime gateway from the snapshot.
bash -c ./create_lxc_gateway_zfs_snapshot.sh