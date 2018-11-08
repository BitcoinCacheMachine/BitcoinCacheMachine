#!/usr/bin/env bash

set -eu
cd "$(dirname "$0")"

BCM_REMOVE_TEMPLATE=0

for i in "$@"
do
case $i in
    --remove-template=*)
    BCM_REMOVE_TEMPLATE=1
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done


# delete container 'bcm-gateway'
if [[ $BCM_GATEWAY_CONTAINER_DELETE = "true" ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_container.sh $BCM_LXC_GATEWAY_CONTAINER_NAME"
fi


# delete BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME
if [[ $BCM_GATEWAY_STORAGE_DOCKERVOL_DELETE = "true" ]]; then
    bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_storage.sh $BCM_LXC_GATEWAY_STORAGE_DOCKERVOL_NAME"
fi

if [[ $BCM_REMOVE_TEMPLATE == 1 ]]; then
    # delte container gateway-template
    if [[ $BCM_GATEWAY_CONTAINER_TEMPLATE_DELETE = "true" ]]; then
        bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_container.sh $BCM_LXC_GATEWAY_CONTAINER_TEMPLATE_NAME"
    fi

    # delete the profile bcm-gateway-profile
    if [[ $BCM_GATEWAY_PROFILE_GATEWAYPROFILE_DELETE = "true" ]]; then
        bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_profile.sh bcm-gateway-profile"
    fi
    
    # delete lxc networks
    if [[ $BCM_GATEWAY_NETWORKS_DELETE = "true" ]]; then
        bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_network.sh bcmbrGWNat"
    fi

    if [[ $BCM_GATEWAY_NETWORKS_DELETE = "true" ]]; then
        bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_network.sh bcmNet"
    fi
fi

rm -rf $BCM_RUNTIME_DIR/runtime/$(lxc remote get-default)/$BCM_LXC_GATEWAY_CONTAINER_NAME