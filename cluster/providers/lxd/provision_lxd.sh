#!/usr/bin/env bash

# this script gets your local LXD instance configured as a single-node LXD cluster
# all BCM scripts assume that provisioning is against an LXD cluster (single or multi-node)
echo "Executing provision_lxd.sh"

set -eu

cd "$(dirname "$0")"

export BCM_ADMIN_MACHINE_LXD_LISTEN_IP="127.0.0.1"
export BCM_LXD_SECRET=$(apg -n 1 -m 30 -M CN)

echo "BCM_BCM_CLUSTER_DIR: $BCM_BCM_CLUSTER_DIR"
if [[ ! -d $BCM_BCM_CLUSTER_DIR ]]; then
    mkdir -p $BCM_BCM_CLUSTER_DIR
fi

if [[ ! -d $BCM_BCM_CLUSTER_DIR/runtime ]]; then
    mkdir -p $BCM_BCM_CLUSTER_DIR/runtime
fi

if [[ ! -f $BCM_BCM_CLUSTER_DIR/lxd_preseed.yml ]]; then
    # substitute the variables in am_lxd_preseed.yml
    envsubst < ./am_lxd_preseed.yml > $BCM_BCM_CLUSTER_DIR/lxd_preseed.yml
    bash -c "cat $BCM_BCM_CLUSTER_DIR/lxd_preseed.yml | sudo lxd init --preseed"
    echo "LXD daemon has been configured and is now primed to receive BCM components."
    echo "To deploy a BCM project to a cluster, use 'bcm project deploy <BCM_PROJECT_NAME> -c=<BCM_CLUSTER_NAME>'"
else
    echo "lxd_preseed.yml already exists."
fi
