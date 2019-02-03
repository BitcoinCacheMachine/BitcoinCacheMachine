#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# shellcheck disable=1090
source "$BCM_GIT_DIR/env"

# echo "Deploying rsyncd to 'cachestack'."
# lxc exec cachestack -- mkdir -p /apps/rsyncd
# lxc exec cachestack -- mkdir -p /apps/rsyncd/.ssh
# lxc file push $BCM_RUNTIME_DIR/endpoints/"$(lxc remote get-default)"/.ssh/cachestack-rsync-key.pub cachestack/apps/rsyncd/authorized_keys
# lxc file push ./rsyncd.conf cachestack/apps/rsyncd/rsyncd.conf
# lxc file push ./rsyncd.yml cachestack/apps/rsyncd/rsyncd.yml
# lxc exec cachestack -- env BCS_INSTALL_RSYNCD_BUILD_IMAGE=$BCS_INSTALL_RSYNCD_BUILD_IMAGE docker stack deploy -c /apps/rsyncd/rsyncd.yml rsyncd

# wait-for-it -t 0 cachestack.lxd:2222

# if [[ $BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED = "true" ]]; then
#     lxc exec cachestack -- mkdir -p cachestack/apps/bitcoind/data

#     # if the directory exists, then we're good to go.
#     if [ -d "$BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED_SOURCEDIR" ]; then

#         # TODO ugprade basic authentication to SSH keys
#         echo "$BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED_SOURCEDIR on $HOSTNAME will be pushed to cachestack rsyncd."
#         SSH_KEY_PATH="$BCM_RUNTIME_DIR/endpoints/lexx/.ssh/cachestack-rsync-key"

#         rsync -av -e "ssh -i $SSH_KEY_PATH -p 2222 -l rsync -o StrictHostKeyChecking=no" $BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED_SOURCEDIR/ cachestack.lxd:bitcoind_testnet_data
#     fi
# fi
