#!/bin/bash

if [[ $(lxc list | grep bcm-rsync-builder) ]]; then
    # let's get a fresh LXC host that's configured to push/pull to gateway registreis
    bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/bcmnet/delete_instance.sh bcm-rsync-builder"
    

    bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_storage.sh rsync bcm-bcmnet-builder-rsync-dockervol"

    rm -rf $BCM_RUNTIME_DIR/runtime/$(lxc remote get-default)/bcm-rsync-builder/
fi


if [[ $(lxc list | grep bcm-rsync) ]]; then
    # let's get a fresh LXC host that's configured to push/pull to gateway registreis
    bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/bcmnet/delete_instance.sh bcm-rsync"


    bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/delete_lxc_storage.sh rsync bcm-bcmnet-rsync-dockervol"

    rm -rf $BCM_RUNTIME_DIR/runtime/$(lxc remote get-default)/bcm-rsync/
fi

