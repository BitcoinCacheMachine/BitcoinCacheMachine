#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

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
