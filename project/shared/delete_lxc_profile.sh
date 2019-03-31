#!/bin/bash

set -Eeuo pipefail

PROFILE_NAME=

for i in "$@"; do
    case $i in
        --profile-name=*)
            PROFILE_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

# delete the profile if it exists.
if lxc profile list | grep -q "$PROFILE_NAME"; then
    lxc profile delete "$PROFILE_NAME"
fi
