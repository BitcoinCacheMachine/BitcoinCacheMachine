#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# determine if we need to build the image.
if [[ $BCS_INSTALL_RSYNCD_BUILD = "true" ]]; then
    echo "Building and pushing $BCS_INSTALL_RSYNCD_BUILD_IMAGE to the private registry hosted on 'cachestack'."

    lxc exec cachestack -- mkdir -p /apps/rsyncd
    lxc file push ./Dockerfile cachestack/apps/rsyncd/Dockerfile
    lxc file push ./entrypoint.sh cachestack/apps/rsyncd/entrypoint.sh

    # build the rsync image. We don't need to put it in a private registry I don't think.
    lxc exec cachestack -- docker build -t "$BCS_INSTALL_RSYNCD_BUILD_IMAGE" /apps/rsyncd
    lxc exec cachestack -- docker push "$BCS_INSTALL_RSYNCD_BUILD_IMAGE"
fi

echo "Deploying rsyncd to 'cachestack'."
lxc exec cachestack -- mkdir -p /apps/rsyncd
lxc exec cachestack -- mkdir -p /apps/rsyncd/.ssh
lxc file push ~/.ssh/authorized_hosts cachestack/apps/rsyncd/.ssh/authorized_keys
lxc file push ./rsyncd.conf cachestack/apps/rsyncd/rsyncd.conf
lxc file push ./rsyncd.yml cachestack/apps/rsyncd/rsyncd.yml
lxc exec cachestack -- env BCS_INSTALL_RSYNCD_BUILD_IMAGE=$BCS_INSTALL_RSYNCD_BUILD_IMAGE docker stack deploy -c /apps/rsyncd/rsyncd.yml rsyncd

lxc exec cachestack -- wait-for-it -t 0 127.0.0.1:873

if [[ $BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED = "true" ]]; then
    lxc exec cachestack -- mkdir -p cachestack/apps/bitcoind/data

    # if the directory exists, then we're good to go.
    if [ -d "$BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED_SOURCEDIR" ]; then
        # TODO ugprade basic authentication to SSH keys
        echo "$BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED_SOURCEDIR on $HOSTNAME will be pushed to cachestack rsyncd."
        sshpass -p "pass" rsync -av $BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED_SOURCEDIR rsync://user@cachestack/volume/bitcoind_testnet_fullblocks
    fi
fi
