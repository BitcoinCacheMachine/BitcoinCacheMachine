#!/bin/bash

MASTER_NODE=$(lxc info | grep server_name | xargs | awk 'NF>1{print $NF}')
export MASTER_NODE=$MASTER_NODE

# shellcheck disable=SC1091
source ../host_template/defaults.sh
