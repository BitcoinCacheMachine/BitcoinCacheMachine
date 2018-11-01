#!/bin/bash

set -eu

echo "in destroy.sh"

if [[ -z $BCM_CLUSTER_NAME ]]; then
    echo "BCM_CLUSTER_NAME is not set. Exiting."
    exit
fi

DIR=~/.bcm/clusters/$BCM_CLUSTER_NAME
CLUSTER_ENDPOINTS=$(bcm cluster list -c=$BCM_CLUSTER_NAME --endpoints)
echo "CLUSTER_ENDPOINTS: $CLUSTER_ENDPOINTS"
if [[ ! -d $DIR ]]; then
    echo "BCM cluster directory $DIR does not exist. Nothing deleted."
    exit
fi

function deleteBCMCluster {
    $BCM_LOCAL_GIT_REPO/cluster/providers/lxd/snap_uninstall_lxd.sh

    if [[ -d $DIR ]]; then
        sudo rm -rf $DIR
        echo "Deleted contents of $DIR. Note ~/.bcm is a git repository and manages versions and history of all files."
    fi
}

for fn in ``; do
    echo "the next file is $fn"
    cat $fn
done

# CONTINUE=0
# if [[ $BCM_FORCE_FLAG = "false" ]]; then
#     read -p "Are you sure you want to delete the BCM cluster? [y/n]:  " choice
#     case "$choice" in 
#         y|Y ) CONTINUE=1;;
#         * ) echo "invalid";;
#     esac
# else
#     CONTINUE=1
# fi

# if [[ $CONTINUE = 1 ]]; then
#     echo ""
#     deleteBCMCluster
#     echo ""
# fi