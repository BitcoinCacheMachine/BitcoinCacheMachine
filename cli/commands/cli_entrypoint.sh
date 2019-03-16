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

BCM_HELP_FLAG=0
BCM_FORCE_FLAG=0

for i in "$@"; do
    case $i in
        --help)
            BCM_HELP_FLAG=1
            shift # past argument=value
        ;;
        --force)
            BCM_FORCE_FLAG=1
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

export BCM_HELP_FLAG="$BCM_HELP_FLAG"
export BCM_FORCE_FLAG="$BCM_FORCE_FLAG"

if [[ "$BCM_CLI_COMMAND" == "reset" ]]; then
    ./reset.sh "$@"
    exit
fi

if [[ "$BCM_CLI_COMMAND" == "init" ]]; then
    ./init.sh "$@"
    exit
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
fi

if [[ "$BCM_CLI_COMMAND" == "stack" ]]; then
    ./stack/entrypoint.sh "$@"
fi

if [[ "$BCM_CLI_COMMAND" == "bitcoin-cli" || "$BCM_CLI_COMMAND" == "lightning-cli" ]]; then
    ./stack_cli/entrypoint.sh "$@"
fi

if [[ "$BCM_CLI_COMMAND" == "deprovision" ]]; then
    bash -c "$BCM_GIT_DIR/project/destroy.sh"
fi

if [[ $BCM_HELP_FLAG == 1 ]]; then
    cat ./help.txt
fi