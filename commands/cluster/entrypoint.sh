#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

VALUE=${2:-}
if [ ! -z "${VALUE}" ]; then
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

# bcm cluster create provisions a new BCM cluster to the localhost
if [[ $BCM_CLI_VERB == "create" ]]; then
    bash -c "$BCM_COMMAND_DIR/cluster/cluster_create.sh"
fi

# this is where we implement 'bcm cluster destroy'
if [[ $BCM_CLI_VERB == "clear" ]]; then
    bash -c "./clear_lxd.sh"
fi