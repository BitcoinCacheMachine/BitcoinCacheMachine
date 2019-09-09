#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_CLI_COMMAND=

if [[ ! -z ${1+x} ]]; then
    BCM_CLI_COMMAND="$1"
else
    cat ./help.txt
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

export BCM_FORCE_FLAG="$BCM_FORCE_FLAG"
export BCM_VOLUMES_FLAG="$BCM_VOLUMES_FLAG"
BCM_CLUSTER_NAME="$(lxc remote get-default)"
export BCM_CLUSTER_NAME="$BCM_CLUSTER_NAME"
ENDPOINT_NAME="$(lxc info | grep "server_name: " | awk 'NF>1{print $NF}')"
export BCM_CLUSTER_DIR="$BCM_CLUSTERS_DIR/$BCM_CLUSTER_NAME"
export BCM_ENDPOINT_DIR="$BCM_CLUSTER_DIR/$ENDPOINT_NAME"


# commands BEFORE the the build stage DO NOT REQUIRE docker images at the controller.
if [[ "$BCM_CLI_COMMAND" == "info" ]]; then
    ./info.sh "$@"
    exit
fi

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

bash -c "$BCM_GIT_DIR/controller/build.sh"
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

if [[ "$BCM_CLI_COMMAND" == "ssh" ]]; then
    ./ssh/entrypoint.sh "$@"
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
