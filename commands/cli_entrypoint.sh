#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_CLI_COMMAND=

if [[ ! -z ${1+x} ]]; then
    BCM_CLI_COMMAND="$1"
else
    # if we get here, then the user didn't supply the correct resonse.
    echo "ERROR: Please supply a bcm command."
    cat ./help.txt
    exit
fi

export BCM_CLI_COMMAND="$BCM_CLI_COMMAND"

#shopt -s expand_aliases

BCM_FORCE_FLAG=0
BCM_VOLUMES_FLAG=0

for i in "$@"; do
    case $i in
        --force)
            BCM_FORCE_FLAG=1
        ;;
        --delete)
            BCM_VOLUMES_FLAG=1
        ;;
        *)
            # unknown option
        ;;
    esac
done

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

# If our local CLI target SSH hostname is on another machine, then
# we should execute it on the reomte machine.
if [[ "$BCM_SSH_HOSTNAME" != "localhost" ]]; then
    bash -c './ssh/entrypoint.sh "$@" --execute --command="$@"'
    exit
else
    
    # these commands will be executed by the local terminal
    export BCM_FORCE_FLAG="$BCM_FORCE_FLAG"
    export BCM_VOLUMES_FLAG="$BCM_VOLUMES_FLAG"
    RUNNING_CONTAINERS="$(lxc list --format csv --columns ns | grep "RUNNING")" || true
    CLUSTER_ENDPOINTS="$(lxc cluster list --format csv | grep "$BCM_SSH_HOSTNAME" | awk -F"," '{print $1}')"
    CLUSTER_NODE_COUNT=$(echo "$CLUSTER_ENDPOINTS" | wc -l)
    export RUNNING_CONTAINERS="$RUNNING_CONTAINERS"
    export CLUSTER_NODE_COUNT="$CLUSTER_NODE_COUNT"
    export CLUSTER_ENDPOINTS="$CLUSTER_ENDPOINTS"
    
    if [[ "$BCM_CLI_COMMAND" == "cluster" ]]; then
        ./cluster/entrypoint.sh "$@"
        exit
    fi
    
    if [[ "$BCM_CLI_COMMAND" == "show" ]]; then
        ./show.sh
        exit
    fi
    
    if [[ "$BCM_CLI_COMMAND" == "stack" ]]; then
        # let's make sure our docker swarm master is available for querying.
        if ! lxc list --format csv --columns n,s | grep -q "$BCM_MANAGER_HOST_NAME"; then
            bcm tier create bitcoin
        fi
        
        # if the manager is stopped, start it.
        if lxc list --format csv --columns n,s | grep -q "$BCM_MANAGER_HOST_NAME,STOPPED"; then
            lxc start "$BCM_MANAGER_HOST_NAME"
            bash -c "$BCM_LXD_OPS/wait_for_dockerd.sh --container-name=$BCM_MANAGER_HOST_NAME"
        fi
        
        ./stack/entrypoint.sh "$@"
        exit
    fi
    
    if [[ "$BCM_CLI_COMMAND" == "tier" ]]; then
        ./tier/entrypoint.sh "$@"
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
    
    
    # set our GNUPGHOME to the user cert directory
    # if there is no certificate, go ahead and create it.
    if [[ ! -d "$GNUPGHOME/trezor" ]]; then
        bash -c "$BCM_GIT_DIR/commands/init.sh"
    fi
    
    ./controller/build_docker_image.sh --image-title="trezor" --base-image="$BASE_DOCKER_IMAGE"
    ./controller/build_docker_image.sh --image-title="gpgagent" --base-image="bcm-trezor:$BCM_VERSION"
    ./controller/build_docker_image.sh --image-title="ots" --base-image="bcm-trezor:$BCM_VERSION"
    
    if [[ "$BCM_CLI_COMMAND" == "controller" ]]; then
        ./controller/entrypoint.sh "$@"
        exit
    fi
    
    if [[ "$BCM_CLI_COMMAND" == "init" ]]; then
        ./init.sh "$@"
    fi
    
    if [[ "$BCM_CLI_COMMAND" == "pass" ]]; then
        ./pass/entrypoint.sh "$@"
        exit
    fi
    
    if [[ "$BCM_CLI_COMMAND" == "git" ]]; then
        ./git/entrypoint.sh "$@"
        exit
    fi
    
    if [[ "$BCM_CLI_COMMAND" == "file" ]]; then
        ./file/entrypoint.sh "$@"
        exit
    fi
    
    if [[ "$BCM_CLI_COMMAND" == "web" ]]; then
        ./web/entrypoint.sh "$@"
        exit
    fi
    
    if [[ "$BCM_CLI_COMMAND" == "logs" ]]; then
        ./stack_cli/entrypoint.sh "$@"
        exit
    fi
    
    if [[ "$BCM_CLI_COMMAND" == "get-ip" ]]; then
        ./get/entrypoint.sh "$@"
        exit
    fi
    
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
fi
