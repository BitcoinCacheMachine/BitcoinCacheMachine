#!/bin/bash

set -Eeuox pipefail

STACK_NAME=

for i in "$@"; do
    case $i in
        --stack-name=*)
            STACK_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

# running the stack up file.
UP_FILE="$BCM_STACKS_DIR/$STACK_NAME/up.sh"
if [[ -f "$UP_FILE" ]]; then
    BCM_BACKUP_DIR="$BCM_BACKUP_DIR" bash -c "$UP_FILE" "$@"
else
    echo "Error: BCM does not support stack '$STACK_NAME'. Check your spelling."
fi