#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# purpose of this script is to call the scripts that are necessary to deploy BCM
# we start bottom up (i.e., LXC image, LXC containers, docker images, docker containers, etc)
# and terminate each script upon service activation.

FRONT_END=0

for i in "$@"; do
    case $i in
        --frontend)
            FRONT_END=1
        ;;
        *)
            # unknown option
        ;;
    esac
done

if ! lxc project list --format csv | grep -q "default (current)"; then
    lxc project switch default
fi

if ! lxc storage list --format csv | grep -q "bcm-"; then
    echo "WARNING: The lxc storage pool 'bcm_root' doesn't exist. You may need to run 'sudo bash -c BCM_GIT_DIR/install.sh'."
    exit
fi

# We start by defining a LXC System Image to run our docker daemon's in.
if ! lxc image list --format csv | grep -q "$LXC_BCM_BASE_IMAGE_NAME"; then
    # only continue if the necessary image exists.
    bash -c "$BCM_GIT_DIR/project/create_bcm_host_template.sh"
fi

# Let's define the LXC project. All BCM-specific content is separated by project
# (if we want multitenancy within a Type-1 VM instance) or locally.
if ! lxc project list --format csv  | grep -q "$BCM_PROJECT"; then
    lxc project create "$BCM_PROJECT"
    
    # these two commands means that each project will
    # inherit profiles and images contained in the default project.
    lxc project set "$BCM_PROJECT" features.images false
    lxc project set "$BCM_PROJECT" features.profiles false
fi

if ! lxc project list --format csv | grep -q "$BCM_PROJECT (current)"; then
    lxc project switch "$BCM_PROJECT"
fi

# if the manager is stopped, start it.
if ! lxc list --format csv --columns n,s | grep -q "$BCM_MANAGER_HOST_NAME,RUNNING"; then
    bash -c "$BCM_GIT_DIR/project/tiers/manager/up.sh"
else
    echo "INFO: LXC host '$BCM_MANAGER_HOST_NAME' is running."
fi


# start the kafka tier
if ! lxc list --format csv --columns n,s | grep -q "$BCM_KAFKA_HOST_NAME,RUNNING"; then
    bash -c "$BCM_GIT_DIR/project/tiers/kafka/up.sh"
else
    echo "INFO: LXC host '$BCM_KAFKA_HOST_NAME' is running."
fi

# start the underlay tier
if ! lxc list --format csv --columns n,s | grep -q "$BCM_UNDERLAY_HOST_NAME,RUNNING"; then
    bash -c "$BCM_GIT_DIR/project/tiers/underlay/up.sh"
else
    echo "INFO: LXC host '$BCM_UNDERLAY_HOST_NAME' is running."
fi

# start the bitcoin tier
if ! lxc list --format csv --columns n,s | grep -q "$BCM_BITCOIN_HOST_NAME,RUNNING"; then
    bash -c "$BCM_GIT_DIR/project/tiers/bitcoin/up.sh"
else
    echo "INFO: LXC host '$BCM_BITCOIN_HOST_NAME' is running."
fi

# let's make sure the toronion is available first.
if ! lxc exec "$BCM_MANAGER_HOST_NAME" -- docker stack list --format '{{ .Name }}' | grep "$BCM_ACTIVE_CHAIN" | grep "$STACK_NAME" | grep -q toronion; then
    bash -c "$BCM_LXD_OPS/up_bcm_stack.sh --stack-name=toronion"
fi

# # let's make sure the tor proxy script is executed, if necessary.
# if ! lxc exec "$BCM_MANAGER_HOST_NAME" -- docker stack list --format '{{ .Name }}' | grep "$BCM_ACTIVE_CHAIN" | grep "$STACK_NAME" | grep -q torproxy; then
#     bash -c "$BCM_LXD_OPS/up_bcm_stack.sh --stack-name=torproxy"
# fi

