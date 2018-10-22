#!/usr/bin/env bash

# this script gets your local LXD instance configured as a single-node LXD cluster
# all BCM scripts assume that provisioning is against an LXD cluster (single or multi-node)

set -e

export BCM_LXD_CLUSTER_NAME="dev_machine"
export BCM_dev_machine_LXD_LISTEN_IP="127.0.0.1"
export BCM_LXD_SECRET=$(apg -n 1 -m 30 -M CN)

BCM_CLUSTER_ROOT=~/.bcm/clusters/$BCM_LXD_CLUSTER_NAME
BCM_CLUSTER_PROJECTS_ROOT_DIR=$BCM_CLUSTER_ROOT/lxd_projects
BCM_ENDPOINT_ROOT=$BCM_CLUSTER_ROOT/endpoints/local
BCM_ENDPOINT_LXD_ROOT=$BCM_ENDPOINT_ROOT/lxd

if [[ ! -d $BCM_CLUSTER_ROOT ]]; then
    mkdir -p $BCM_CLUSTER_ROOT
fi

if [[ ! -d $BCM_CLUSTER_PROJECTS_ROOT_DIR ]]; then
    mkdir -p $BCM_CLUSTER_PROJECTS_ROOT_DIR
fi

if [[ ! -d $BCM_ENDPOINT_ROOT ]]; then
    mkdir -p $BCM_ENDPOINT_ROOT
fi

if [[ ! -d $BCM_ENDPOINT_LXD_ROOT ]]; then
    mkdir -p $BCM_ENDPOINT_LXD_ROOT
fi

if [[ ! -f $BCM_ENDPOINT_LXD_ROOT/preseed.yml ]]; then
    # substitute the variables in lxd_master_preseed.yml
    envsubst < ./am_lxd_preseed.yml > $BCM_ENDPOINT_LXD_ROOT/preseed.yml
    sleep 5
    bash -c "cat $BCM_ENDPOINT_LXD_ROOT/preseed.yml | sudo lxd init --preseed"
fi
