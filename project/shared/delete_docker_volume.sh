#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

LXC_HOST="$BCM_BITCOIN_HOST_NAME"
STACK_NAME=
VOLUME_NAME=

for i in "$@"; do
    case $i in
        --lxc-hostname=*)
            LXC_HOST="${i#*=}"
            shift # past argument=value
        ;;
        --stack-name=*)
            STACK_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --volume-name=*)
            VOLUME_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

# push the stack and build files
lxc exec "$LXC_HOST" -- docker volume rm -f "$STACK_NAME-$BCM_ACTIVE_CHAIN""""_""$VOLUME_NAME"