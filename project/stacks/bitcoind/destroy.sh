#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1090
source "$BCM_GIT_DIR/env"

CHAIN=
for i in "$@"; do
    case $i in
        --chain=*)
            CHAIN="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z $CHAIN ]]; then
    echo "CHAIN not specified. Exiting"
    exit
fi


bash -c "$BCM_LXD_OPS/remove_docker_stack.sh --stack-name=bitcoind-$CHAIN"
