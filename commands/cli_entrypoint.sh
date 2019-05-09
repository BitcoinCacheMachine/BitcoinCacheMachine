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

export BCM_FORCE_FLAG="$BCM_FORCE_FLAG"
export BCM_VOLUMES_FLAG="$BCM_VOLUMES_FLAG"
CLUSTER_NAME="$(lxc remote get-default)"
export CLUSTER_NAME="$CLUSTER_NAME"

if [[ "$BCM_CLI_COMMAND" == "get-chain" ]]; then
    ./chain/getchain.sh
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

if [[ "$BCM_CLI_COMMAND" == "info" ]]; then
    ./info.sh "$@"
    exit
fi

if [[ "$BCM_CLI_COMMAND" == "cluster" ]]; then
    ./cluster/entrypoint.sh "$@"
    exit
fi

if [[ "$BCM_CLI_COMMAND" == "ssh" ]]; then
    ./ssh/entrypoint.sh "$@"
    exit
fi

if [[ "$BCM_CLI_COMMAND" == "show" ]]; then
    ./show.sh
    exit
fi

if [[ "$BCM_CLI_COMMAND" == "tier" ]]; then
    ./tier/entrypoint.sh "$@"
    exit
fi

if [[ "$BCM_CLI_COMMAND" == "stack" ]]; then
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

if [[ "$BCM_CLI_COMMAND" == "logs" ]]; then
    ./stack_cli/entrypoint.sh "$@"
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

if [[ "$BCM_CLI_COMMAND" == "deprovision" ]]; then
    bash -c "$BCM_GIT_DIR/project/destroy.sh" "$@"
    exit
fi

if [[ $BCM_HELP_FLAG == 1 ]]; then
    cat ./help.txt
fi
