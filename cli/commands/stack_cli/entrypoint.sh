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

