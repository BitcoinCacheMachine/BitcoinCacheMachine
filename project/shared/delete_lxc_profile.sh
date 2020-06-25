#!/bin/bash

set -Eeuo pipefail

PROFILE_NAME=

for i in "$@"; do
    case $i in
        --profile-name=*)
            PROFILE_NAME="${i#*=}"
            shift
        ;;
        *)
            # unknown option
        ;;
    esac
done

# delete the profile if it exists.
if lxc profile list --format csv | grep "$PROFILE_NAME" | grep -q ",0"; then
    lxc profile delete "$PROFILE_NAME"
fi
