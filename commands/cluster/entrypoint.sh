#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

VALUE=${2:-}
if [ -n "${VALUE}" ]; then
    BCM_CLI_VERB="$2"
else
    echo "Please provide a cluster command."
    cat ./help.txt
    exit
fi

for i in "$@"; do
    case $i in
        --create)
            BCM_CLI_VERB="create"
        ;;
        *) ;;
        
    esac
done

if [[ $BCM_HELP_FLAG == 1 ]]; then
    cat ./help.txt
    exit
fi
