#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

BCM_CLI_COMMAND=

if [[ ! -z ${1+x} ]]; then
    BCM_CLI_COMMAND="$1"
else
    # if we get here, then the user didn't supply the correct resonse.
    cat ./help.txt
    exit
fi

export BCM_CLI_COMMAND="$BCM_CLI_COMMAND"

BCM_FORCE_FLAG=0
BCM_VOLUMES_FLAG=0
ALL_FLAG=0

for i in "$@"; do
    case $i in
        --force)
            BCM_FORCE_FLAG=1
        ;;
        --delete)
            BCM_VOLUMES_FLAG=1
        ;;
        --all)
            ALL_FLAG=1
        ;;
        *)
            # unknown option
        ;;
    esac
done

export ALL_FLAG="$ALL_FLAG"

if [[ "$BCM_CLI_COMMAND" == "reset" ]]; then
    ./reset.sh "$@"
    exit
fi

if [[ -z "$BCM_SSH_USERNAME" ]]; then
    echo "Error: BCM_SSH_USERNAME not passed correctly."
    exit
fi

# commands BEFORE the the build stage DO NOT REQUIRE docker images at the controller.
if [[ "$BCM_CLI_COMMAND" == "info" ]]; then
    ./info.sh "$@"
    exit
fi
# commands BEFORE the the build stage DO NOT REQUIRE docker images at the controller.
if [[ "$BCM_CLI_COMMAND" == "show" ]]; then
    ./show.sh "$@"
    exit
fi

if [[ "$BCM_CLI_COMMAND" == "clear" ]]; then
    ./clear_lxd.sh "$@"
    exit
fi

# for hdd storage pool
# STORAGE_PATH="$HOME/bcm_storage_hdd"
# mkdir -p "$STORAGE_PATH"
# lxc storage create "bcm-hdd" btrfs size=20GB

# This for loop makes sure that all subsequent commands have access to the
# bcm LXD profiles.
for STORAGE_POOL in hdd ssd sd; do
    # if the profile doesn't already exist, we create it.
    if ! lxc storage list --format csv | grep -q "bcm-$STORAGE_POOL"; then
        # let's first check to see if the loop device already exists.
        LOOP_DEVICE=
        if losetup --list --output NAME,BACK-FILE | grep -q "$IMAGE_PATH"; then
            LOOP_DEVICE="$(losetup --list --output NAME,BACK-FILE | grep $IMAGE_PATH | head -n1 | cut -d " " -f1)"
            lxc storage create "bcm-$STORAGE_POOL" btrfs source="$LOOP_DEVICE"
        else
            echo "ERROR: Loop device for storage pool '$STORAGE_POOL' does not exist!"
            exit
        fi
    fi
done

# This for loop makes sure that all subsequent commands have access to the
# bcm LXD profiles.
for PROFILE_NAME in ssd hdd sd unprivileged privileged; do
    # if the profile doesn't already exist, we create it.
    if ! lxc profile list --format csv | grep -q "bcm-$PROFILE_NAME"; then
        lxc profile create "bcm-$PROFILE_NAME"
        cat "./lxd_profiles/$PROFILE_NAME.yml" | lxc profile edit "bcm-$PROFILE_NAME"
    fi
done

# commands BEFORE the the build stage DO NOT REQUIRE docker images at the controller.
if [[ "$BCM_CLI_COMMAND" == "vm" ]]; then
    bash -c ./vm/destroy_vm.sh
    bash -c ./vm/up_vm.sh
    exit
fi


# commands BEFORE the the build stage DO NOT REQUIRE docker images at the controller.
if [[ "$BCM_CLI_COMMAND" == "deploy" ]]; then
    bash -c "$BCM_PROJECT_DIR/deploy.sh $@"
    exit
fi


# # If our local CLI target SSH hostname is on another machine, then
# # we should execute it on the reomte machine.
# if [[ "$BCM_SSH_HOSTNAME" != "localhost" ]]; then
#     bash -c './ssh/entrypoint.sh "$@" --execute --command="$@"'
#     exit
# else

# these commands will be executed by the local terminal
export BCM_FORCE_FLAG="$BCM_FORCE_FLAG"
export BCM_VOLUMES_FLAG="$BCM_VOLUMES_FLAG"
# RUNNING_CONTAINERS="$(lxc list --format csv --columns ns | grep "RUNNING")" || true
# CLUSTER_ENDPOINTS="$(lxc cluster list --format csv | grep "$BCM_SSH_HOSTNAME" | awk -F"," '{print $1}')"
# CLUSTER_NODE_COUNT=$(echo "$CLUSTER_ENDPOINTS" | wc -l)
# export RUNNING_CONTAINERS="$RUNNING_CONTAINERS"
# export CLUSTER_NODE_COUNT="$CLUSTER_NODE_COUNT"
# export CLUSTER_ENDPOINTS="$CLUSTER_ENDPOINTS"

# if [[ "$BCM_CLI_COMMAND" == "cluster" ]]; then
#     ./cluster/entrypoint.sh "$@"
#     exit
# fi


if [[ "$BCM_CLI_COMMAND" == "stack" ]]; then
    
    # if the manager is stopped, start it.
    if lxc list --format csv --columns n,s | grep -q "$BCM_MANAGER_HOST_NAME,STOPPED"; then
        lxc start "$BCM_MANAGER_HOST_NAME"
        bash -c "$BCM_LXD_OPS/wait_for_dockerd.sh --container-name=$BCM_MANAGER_HOST_NAME"
    fi
    
    ./stack/entrypoint.sh "$@"
    exit
fi


if [[ "$BCM_CLI_COMMAND" == "restore" ]]; then
    ./backuprestore/entrypoint.sh "$@" --restore
    exit
fi

if [[ "$BCM_CLI_COMMAND" == "backup" ]]; then
    ./backuprestore/entrypoint.sh "$@"
    exit
fi

if [[ "$BCM_CLI_COMMAND" == "bitcoin-cli" || "$BCM_CLI_COMMAND" == "lightning-cli" || "$BCM_CLI_COMMAND" == "lncli" ]]; then
    ./stack_cli/entrypoint.sh "$@"
    exit
fi

# ./controller/build_docker_image.sh --image-title="trezor" --base-image="$BASE_DOCKER_IMAGE"
# ./controller/build_docker_image.sh --image-title="gpgagent" --base-image="bcm-trezor:$BCM_VERSION"
# ./controller/build_docker_image.sh --image-title="ots" --base-image="bcm-trezor:$BCM_VERSION"

# if [[ "$BCM_CLI_COMMAND" == "init" ]]; then
#     ./init.sh "$@"
#     exit
# fi

# set our GNUPGHOME to the user cert directory
# if there is no certificate, go ahead and create it.
# if [[ ! -d "$GNUPGHOME/trezor" ]]; then
#     echo "ERROR: 'The '$GNUPGHOME/trezor' directory does not exist. Please run 'bcm init'."
#     exit
# fi

# if [[ "$BCM_CLI_COMMAND" == "controller" ]]; then
#     ./controller/entrypoint.sh "$@"
#     exit
# fi

# if [[ "$BCM_CLI_COMMAND" == "pass" ]]; then
#     ./pass/entrypoint.sh "$@"
#     exit
# fi

# if [[ "$BCM_CLI_COMMAND" == "git" ]]; then
#     ./git/entrypoint.sh "$@"
#     exit
# fi

# if [[ "$BCM_CLI_COMMAND" == "file" ]]; then
#     ./file/entrypoint.sh "$@"
#     exit
# fi

# if [[ "$BCM_CLI_COMMAND" == "web" ]]; then
#     ./web/entrypoint.sh "$@"
#     exit
# fi

# if [[ "$BCM_CLI_COMMAND" == "logs" ]]; then
#     ./stack_cli/entrypoint.sh "$@"
#     exit
# fi

# if [[ "$BCM_CLI_COMMAND" == "get-ip" ]]; then
#     ./get/entrypoint.sh "$@"
#     exit
# fi

# run is for running docker containers AT the SDN controller (not in LXC)
if [[ "$BCM_CLI_COMMAND" == "run" ]]; then
    ./run/entrypoint.sh "$@"
    exit
fi

# run is for running docker containers AT the SDN controller (not in LXC)
if [[ "$BCM_CLI_COMMAND" == "run" ]]; then
    ./run/entrypoint.sh "$@"
    exit
fi
# fi
