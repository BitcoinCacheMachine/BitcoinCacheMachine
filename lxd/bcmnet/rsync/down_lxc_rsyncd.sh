#!/bin/bash

if [[ $(lxc list | grep bcm-rsync) ]]; then
    # let's get a fresh LXC host that's configured to push/pull to gateway registreis
    bash -c "$BCM_LOCAL_GIT_REPO/lxd/bcmnet_template/delete_instance.sh bcm-rsync"
fi

if [[ $(lxc list | grep bcm-rsync-builder) ]]; then
    # let's get a fresh LXC host that's configured to push/pull to gateway registreis
    bash -c "$BCM_LOCAL_GIT_REPO/lxd/bcmnet_template/delete_instance.sh bcm-rsync-builder"
fi
