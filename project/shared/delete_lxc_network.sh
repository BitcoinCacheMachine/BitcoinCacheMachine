#!/bin/bash

set -Eeuo pipefail

NETWORK_NAME=

for i in "$@"; do
    case $i in
        --network-name=*)
            NETWORK_NAME="${i#*=}"
            shift
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $NETWORK_NAME ]]; then
    echo "Error. NETWORK_NAME was empty."
    exit
fi

if lxc network list --format csv | grep "$NETWORK_NAME" | grep -q ",0,"; then
    lxc network delete "$NETWORK_NAME"
fi
