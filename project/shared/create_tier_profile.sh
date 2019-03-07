#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_TIER_NAME=
BCM_YAML_PATH=

for i in "$@"; do
    case $i in
        --tier-name=*)
            BCM_TIER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --yaml-path=*)
            BCM_YAML_PATH="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

# first let's install the profile for the TIER.
PROFILE_NAME='bcm_'"$BCM_TIER_NAME"'_profile'
if ! lxc profile list | grep -q "$PROFILE_NAME"; then
    lxc profile create "$PROFILE_NAME"
    
    if [[ -f "$BCM_YAML_PATH" ]]; then
        cat "$BCM_YAML_PATH" | lxc profile edit "$PROFILE_NAME"
    fi
else
    echo "WARNING: LXC profile '$PROFILE_NAME' already exists. It was left unmodified."
fi