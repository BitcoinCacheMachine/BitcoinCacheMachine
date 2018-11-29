#!/bin/bash


# exit script if there's an error anywhere
set -Eeuo pipefail


# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

if [[ ! -z $1 ]]; then

    INSTANCE=$1

    # delete container '$INSTANCE'
    bash -c "$BCM_LXD_OPS/delete_lxc_container.sh true $INSTANCE"

    # delete $INSTANCE-dockervol
    bash -c "$BCM_LXD_OPS/delete_lxc_storage.sh true $INSTANCE-dockervol"

else
    echo "Usage: './destroy_instance.sh INSTANCE' where INSTANCE is a lxc container."
fi
