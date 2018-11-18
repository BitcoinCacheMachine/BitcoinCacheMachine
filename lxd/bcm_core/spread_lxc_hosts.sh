#!/bin/bash

set -eu

BCM_LXC_HOSTNAME=

for i in "$@"
do
case $i in
    --hostname=*)
    BCM_LXC_HOSTNAME="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

if [[ -z $BCM_LXC_HOSTNAME ]]; then
    echo "BCM_LXC_HOSTNAME not set."
    exit
fi

# let's get a bcm-gateway LXC instance on each cluster endpoint.
MASTER_NODE=$(lxc info | grep server_name | xargs | awk 'NF>1{print $NF}')
for endpoint in $(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME); do
    HOST_ENDING=$(echo $endpoint | tail -c 2)
    LXC_HOSTNAME="bcm-$BCM_LXC_HOSTNAME-$(printf %02d $HOST_ENDING)"
    LXC_DOCKERVOL="$LXC_HOSTNAME-dockerdisk"
    
    if [ $endpoint != $MASTER_NODE ]; then
        echo "Creating volume '$LXC_DOCKERVOL' on storage pool bcm_btrfs on cluster member '$endpoint'."
        lxc storage volume create bcm_btrfs $LXC_DOCKERVOL block.filesystem=ext4 --target $endpoint
    else
        lxc storage volume create bcm_btrfs $LXC_DOCKERVOL block.filesystem=ext4
    fi
    
    lxc init --target $endpoint bcm-template $LXC_HOSTNAME --profile=bcm_default --profile=docker_privileged -p 'bcm_'"$BCM_LXC_HOSTNAME"'_profile'

    lxc storage volume attach bcm_btrfs $LXC_DOCKERVOL $LXC_HOSTNAME dockerdisk path=/var/lib/docker
done
