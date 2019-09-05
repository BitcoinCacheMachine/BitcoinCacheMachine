#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

VALUE=${2:-}
if [ ! -z "${VALUE}" ]; then
    STACK_NAME="$2"
else
    echo "Please provide a backup command."
    cat ./help.txt
    exit
fi

LXC_HOST="$BCM_BITCOIN_HOST_NAME"

# if BACKUP=0, then we assume a restore operation.
BACKUP=1

for i in "$@"; do
    case $i in
    --stack=*)
        STACK_NAME="${i#*=}"
        shift # past argument=value
        ;;
    --lxc-host=*)
        LXC_HOST="${i#*=}"
        shift # past argument=value
        ;;
    --restore)
        BACKUP=0
        ;;
    *) ;;
    esac
done

if [[ $BCM_HELP_FLAG == 1 ]]; then
    cat ./help.txt
    exit
fi

STACK_DIR="$BCM_STACKS_DIR/$STACK_NAME"
if [[ ! -d "$STACK_DIR" ]]; then
    echo "Error: Stack is not defined within BCM."
    exit
fi

# stack env file
STACK_ENV_FILE="$STACK_DIR/env.sh"
if [[ ! -f "$STACK_ENV_FILE" ]]; then
    echo "Error: Stack env file '$STACK_ENV_FILE' does not exist."
    exit 1
fi

# source the file so we get bitcoind-specific info
source "$STACK_ENV_FILE"

BACKUP_DESTINATION_DIR="$BCM_WORKING_DIR/$BCM_CLUSTER_NAME/backups/$STACK_NAME"
mkdir -p "$BACKUP_DESTINATION_DIR"

for DOCKER_VOLUME in $STACK_DOCKER_VOLUMES; do
    echo "$DOCKER_VOLUME"
    BCM_DESTINATION_DIR="$BACKUP_DESTINATION_DIR/$DOCKER_VOLUME"
    mkdir -p "$BCM_DESTINATION_DIR"

    echo "CHECK HERE"
    CONTAINER_DIR="$LXC_HOST""/var/lib/docker/volumes/$STACK_NAME-$BCM_ACTIVE_CHAIN""_""$DOCKER_VOLUME/_data"
    if [[ $BACKUP == 1 ]]; then

        # if the stack is running, we stop immediately.  These scripts are only intended for manual backups
        # and services are ASSUMED To be OFF.
        if bcm stack list | grep -q bitcoind; then
            echo "Error: Can't perform a manual backup when 'bitcoind' is running. Use 'bcm stack remove bitcoind' to stop bitcoind services."
            exit 1
        fi

        lxc file pull "$CONTAINER_DIR" "$BCM_DESTINATION_DIR" -r
    elif [[ $BACKUP == 0 ]]; then
        lxc file push "$BCM_DESTINATION_DIR/_data" "$CONTAINER_DIR" -r
    fi
done
