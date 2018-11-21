#!/usr/bin/env bash

set -Eeuo pipefail

BCM_PROFILE_NAME=

for i in "$@"
do
case $i in
    --profile-name=*)
    BCM_PROFILE_NAME="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

# delete the profile if it exists.
if [[ $(lxc profile list | grep "$BCM_PROFILE_NAME") ]]; then
    echo "Deleting lxd profile '$BCM_PROFILE_NAME'."
    lxc profile delete "$BCM_PROFILE_NAME"
fi
