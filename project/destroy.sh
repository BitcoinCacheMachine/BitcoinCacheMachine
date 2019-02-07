#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1091
source "$BCM_GIT_DIR/env"

BCM_PROJECT_NAME=
BCM_DELETE_BCM_IMAGE=0
BCM_DELETE_LXC_BASE=0
BCM_DEPLOY_TIERS=1

for i in "$@"; do
    case $i in
        --project-name=*)
            BCM_PROJECT_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --del-template=*)
            BCM_DELETE_BCM_IMAGE="${i#*=}"
            shift # past argument=value
        ;;
        --del-lxcbase=*)
            BCM_DELETE_LXC_BASE="${i#*=}"
            shift # past argument=value
        ;;
        --all)
            BCM_DELETE_BCM_IMAGE=1
            BCM_DELETE_LXC_BASE=1
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

# quit if there are no BCM environment variables
if ! env | grep -q 'BCM_'; then
    echo "BCM variables not set. Please source BCM environment variables."
    exit
fi

export BCM_PROJECT_NAME="$BCM_PROJECT_NAME"
if [[ $BCM_DEPLOY_TIERS == 1 ]]; then
    ./tiers/destroy.sh --all
fi

# stop dockertemplate
if lxc list --format csv | grep "bcm-host-template" | grep -q "RUNNING"; then
    lxc stop bcm-host-template
fi

# delete dockertemplate
if lxc list --format csv | grep -q "bcm-host-template"; then
    echo "Deleting dockertemplate lxd host."
    lxc delete bcm-host-template
fi

if [[ $BCM_DELETE_BCM_IMAGE == 1 ]]; then
    # remove image bcm-template
    bash -c "$BCM_LXD_OPS/delete_lxc_image.sh --image-name=bcm-template"
fi

# remove image bcm-lxc-base
if [[ $BCM_DELETE_LXC_BASE == 1 ]]; then
    bash -c "$BCM_LXD_OPS/delete_lxc_image.sh --image-name=bcm-lxc-base"
fi

# delete profile 'docker-privileged'
bash -c "$BCM_LXD_OPS/delete_lxc_profile.sh --profile-name=docker_privileged"

# delete profile 'docker-unprivileged'
bash -c "$BCM_LXD_OPS/delete_lxc_profile.sh --profile-name=docker_unprivileged"

if lxc network list --format csv | grep -q "bcmbr0"; then
    lxc network delete bcmbr0
fi


# ensure we have an LXD project defined for this deployment
# you can use lxd projects to deploy mutliple BCM instances on the same set of hardware (i.e., lxd cluster)
if lxc project list | grep -q "$BCM_PROJECT_NAME"; then
    lxc project switch default
    lxc project delete "$BCM_PROJECT_NAME"
fi