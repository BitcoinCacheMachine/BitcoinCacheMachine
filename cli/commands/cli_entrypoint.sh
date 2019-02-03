#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

export BCM_CLI_COMMAND=$1
export BCM_CLI_VERB=$2

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

export BCM_HELP_FLAG=$BCM_HELP_FLAG
export BCM_FORCE_FLAG=$BCM_FORCE_FLAG

if [[ $BCM_CLI_COMMAND == "init" ]]; then
    ./init.sh "$@"
    elif [[ $BCM_CLI_COMMAND == "project" ]]; then
    ./project/entrypoint.sh "$@"
    elif [[ $BCM_CLI_COMMAND == "cluster" ]]; then
    ./cluster/entrypoint.sh "$@"
    elif [[ $BCM_CLI_COMMAND == "git" ]]; then
    ./git/entrypoint.sh "$@"
    elif [[ $BCM_CLI_COMMAND == "file" ]]; then
    ./file/entrypoint.sh "$@"
    elif [[ $BCM_CLI_COMMAND == "ssh" ]]; then
    ./ssh/entrypoint.sh "$@"
    elif [[ $BCM_CLI_COMMAND == "tier" ]]; then
    ./tier/entrypoint.sh "$@"
    elif [[ $BCM_CLI_COMMAND == "pass" ]]; then
    ./pass/entrypoint.sh "$@"
    elif [[ $BCM_CLI_COMMAND == "info" ]]; then
    ./info.sh "$@"
    elif [[ $BCM_CLI_COMMAND == "show" ]]; then
    ./show.sh
else
    cat ./help.txt
fi