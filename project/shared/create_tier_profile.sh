#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

TIER_NAME=
YAML_PATH=

for i in "$@"; do
    case $i in
        --tier-name=*)
            TIER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --yaml-path=*)
            YAML_PATH="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

PROFILE_NAME="bcm-$TIER_NAME"
if [[ $TIER_NAME == bitcoin* ]]; then
    PROFILE_NAME=bcm-bitcoin
fi

if ! lxc profile list | grep -q "$PROFILE_NAME"; then
    lxc profile create "$PROFILE_NAME"
    
    if [[ -f "$YAML_PATH" ]]; then
        cat "$YAML_PATH" | lxc profile edit "$PROFILE_NAME"
    fi
fi