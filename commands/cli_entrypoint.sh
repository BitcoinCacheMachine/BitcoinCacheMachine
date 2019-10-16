#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_CLI_COMMAND=

if [[ ! -z ${1+x} ]]; then
    BCM_CLI_COMMAND="$1"
else
    exit
fi

export BCM_CLI_COMMAND="$BCM_CLI_COMMAND"

shopt -s expand_aliases

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


./controller/build_docker_image.sh --image-title="trezor" --base-image="$BASE_DOCKER_IMAGE"
./controller/build_docker_image.sh --image-title="gpgagent" --base-image="bcm-trezor:$BCM_VERSION"

# If our local CLI target SSH hostname is on another machine, then
# we should execute it on the reomte machine.
if [[ "$BCM_SSH_HOSTNAME" != "$(hostname)" ]]; then
    ./ssh/entrypoint.sh "$@" --execute --command="$@"
    exit
else
    
    # these commands will be executed by the local terminal
    export BCM_FORCE_FLAG="$BCM_FORCE_FLAG"
    export BCM_VOLUMES_FLAG="$BCM_VOLUMES_FLAG"
    
    if [[ "$BCM_CLI_COMMAND" == "cluster" ]]; then
        ./cluster/entrypoint.sh "$@"
        exit
    fi
    
    if [[ "$BCM_CLI_COMMAND" == "show" ]]; then
        ./show.sh
        exit
    fi
    
    if [[ "$BCM_CLI_COMMAND" == "start" ||  "$BCM_CLI_COMMAND" == "stop" || "$BCM_CLI_COMMAND" == "restart"  ]]; then
        ./operations/start_stop_restart.sh
        exit
    fi
    
    if [[ "$BCM_CLI_COMMAND" == "stack" ]]; then
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
    
    # Install docker if we're running this command on a front-end
    if [[ $IS_FRONTEND = 1 ]]; then
        bash -c "./controller/build_all_docker_images.sh"
    fi
    
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
    
    
    if [[ "$BCM_CLI_COMMAND" == "config" ]]; then
        ./config/entrypoint.sh "$@"
        exit
    fi
    
    if [[ "$BCM_CLI_COMMAND" == "set-chain" ]]; then
        ./chain/setchain.sh "$@"
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