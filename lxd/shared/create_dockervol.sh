#!/bin/bash

set -Eeuo pipefail

LXC_CONTAINER_NAME=
LXC_DOCKERVOL_NAME=


for i in "$@"
do
case $i in
    --container-name=*)
    LXC_CONTAINER_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --dockervol-name=*)
    LXC_DOCKERVOL_NAME="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done


if [[ -z $LXC_CONTAINER_NAME ]]; then
    echo "ERROR: BCM_LXC_CONTAINER_NAME was not set. Cannot create a dockervol storage backing."
    exit
fi

if [[ -z $LXC_DOCKERVOL_NAME ]]; then
    export LXC_DOCKERVOL_NAME="$LXC_CONTAINER_NAME-dockervol"
fi

#mkdir -p /var/snap/lxd/common/mntns/var/snap/lxd/common/lxd/storage-pools/$LXC_DOCKERVOL_NAME
lxc storage create --target upstairs $LXC_DOCKERVOL_NAME dir source=/dev/sda3


# CLUSTER_ENDPOINTS=$(bcm cluster list --endpoints --cluster-name=$BCM_CLUSTER_NAME)
# for endpoint in $CLUSTER_ENDPOINTS; do

#     ENDPOINT_DIR=$BCM_CLUSTERS_DIR/$BCM_CLUSTER_NAME/endpoints/$endpoint
#     source $ENDPOINT_DIR/.env

#     if [[ -z $BCM_DOCKERVOL_MOUNTPOINT ]]; then
#         echo "BCM_DOCKERVOL_MOUNTPOINT not set. Exiting"
#         exit
#     fi
#     DOCKER_VOL_DIR=$BCM_DOCKERVOL_MOUNTPOINT/$BCM_CLUSTER_NAME/endpoints/$endpoint
#     mkdir -p $DOCKER_VOL_DIR
#     IMAGE_FILE=$DOCKER_VOL_DIR/dockervol.img
#     dd if=/dev/zero of=$IMAGE_FILE bs=100M count=10

#     # set up a loop device for the .img
#     sudo losetup -fP $IMAGE_FILE
#     echo 'export BCM_DOCKERVOL_LOOPBACK_FILE=''"''$BCM_DOCKERVOL_MOUNTPOINT/'$BCM_CLUSTER_NAME/endpoints/$endpoint/dockervol.img'"' >> $ENDPOINT_DIR/.env
# done



# if [[ ! $(echo $CLUSTER_ENDPOINTS | wc -l) = 1 ]]; then
#     echo "ERROR: TODO HANDLE MULTIPLE CLUSTER NODES."
#     # # we have to do this for each cluster node
#     # for endpoint in $CLUSTER_ENDPOINTS; do
#     #     # only create it if it doesn't already exist.
#     #     if [[ -z $(lxc storage list | grep $LXC_CONTAINER_NAME) ]]; then
#     #         IMAGE_FILE=$BCM_DOCKERVOL_MOUNTPOINT/$BCM_CLUSTER_NAME/endpoints/$endpoint/dockervol.img

#     #         echo "LOOP_DEVICE: $LOOP_DEVICE"
#     #         lxc storage create --target $endpoint $LXC_DOCKERVOL_NAME dir source=$BCM_DOCKERVOL_LOOPBACK_FILE
#     #     fi
#     # done

#     # lxc storage create $LXC_DOCKERVOL_NAME dir
# else

# fi
