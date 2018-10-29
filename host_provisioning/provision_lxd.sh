#!/usr/bin/env bash

# this script gets your local LXD instance configured as a single-node LXD cluster
# all BCM scripts assume that provisioning is against an LXD cluster (single or multi-node)
echo "Executing provision_lxd.sh"

set -e

# call bcm_script_before.sh to ensure we have up-to-date ENV variables.
source "$BCM_LOCAL_GIT_REPO/resources/export_bcm_envs.sh"

export BCM_ADMIN_MACHINE_LXD_LISTEN_IP="127.0.0.1"
export BCM_LXD_SECRET=$(apg -n 1 -m 30 -M CN)

if [[ ! -d $BCM_CLUSTER_ROOT_DIR ]]; then
    mkdir -p $BCM_CLUSTER_ROOT_DIR
fi

if [[ ! -d $BCM_CLUSTER_PROJECTS_ROOT_DIR ]]; then
    mkdir -p $BCM_CLUSTER_PROJECTS_ROOT_DIR
fi

if [[ ! -d $BCM_ENDPOINT_ROOT_DIR ]]; then
    mkdir -p $BCM_ENDPOINT_ROOT_DIR
fi

if [[ ! -d $BCM_ENDPOINT_LXD_ROOT_DIR ]]; then
    mkdir -p $BCM_ENDPOINT_LXD_ROOT_DIR
fi

if [[ ! -f $BCM_ENDPOINT_ROOT_DIR/lxd_preseed.yml ]]; then
    # substitute the variables in am_lxd_preseed.yml
    envsubst < ./am_lxd_preseed.yml > $BCM_ENDPOINT_ROOT_DIR/lxd_preseed.yml
    sleep 5
    bash -c "cat $BCM_ENDPOINT_ROOT_DIR/lxd_preseed.yml | sudo lxd init --preseed"
fi
