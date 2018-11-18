#!/bin/bash

export MASTER_NODE=$(lxc info | grep server_name | xargs | awk 'NF>1{print $NF}')

source ../host_template/defaults.sh
