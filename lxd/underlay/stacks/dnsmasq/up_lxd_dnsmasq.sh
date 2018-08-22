#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

echo "Building local image for running 'underlay' services."

lxc exec underlay -- docker pull ubuntu:bionic
lxc exec underlay -- mkdir -p /apps/dnsmasq
lxc file push ./Dockerfile underlay/apps/dnsmasq/Dockerfile
lxc file push ./dnsmasq.conf underlay/apps/dnsmasq/dnsmasq.conf
lxc exec underlay -- docker build -t bcm/dnsmasq:latest /apps/dnsmasq
lxc exec underlay -- docker run -it --rm bcm/dnsmasq:latest dnsmasq -q -d --conf-file=/etc/dnsmasq.conf --dhcp-broadcast






# lxc exec cachestack -- mkdir -p /apps/rsyncd
# lxc file push ./Dockerfile cachestack/apps/rsyncd/Dockerfile
# lxc file push ./entrypoint.sh cachestack/apps/rsyncd/entrypoint.sh

# # build the rsync image. We don't need to put it in a private registry I don't think.
# lxc exec cachestack -- docker build -t "$BCS_INSTALL_RSYNCD_BUILD_IMAGE" /apps/rsyncd
# lxc exec cachestack -- docker push "$BCS_INSTALL_RSYNCD_BUILD_IMAGE"


# if [[ ! -f ~/.bcm/endpoints/"$(lxc remote get-default)"/.ssh/cachestack-rsync-key.pub ]]; then
#     echo "Generating SSH keys for rsync authentication. Storing at ~/.bcm/endpoints/"$(lxc remote get-default)"/.ssh/cachestack-rsync-key.pub"
#     mkdir -p ~/.bcm/endpoints/"$(lxc remote get-default)"/.ssh
#     ssh-keygen -t rsa -b 2048 -f ~/.bcm/endpoints/"$(lxc remote get-default)"/.ssh/cachestack-rsync-key
# fi

# echo "Deploying rsyncd to 'cachestack'."
# lxc exec cachestack -- mkdir -p /apps/rsyncd
# lxc exec cachestack -- mkdir -p /apps/rsyncd/.ssh
# lxc file push ~/.bcm/endpoints/"$(lxc remote get-default)"/.ssh/cachestack-rsync-key.pub cachestack/apps/rsyncd/authorized_keys
# lxc file push ./rsyncd.conf cachestack/apps/rsyncd/rsyncd.conf
# lxc file push ./rsyncd.yml cachestack/apps/rsyncd/rsyncd.yml
# lxc exec cachestack -- env BCS_INSTALL_RSYNCD_BUILD_IMAGE=$BCS_INSTALL_RSYNCD_BUILD_IMAGE docker stack deploy -c /apps/rsyncd/rsyncd.yml rsyncd

# wait-for-it -t 0 cachestack.lxd:2222
# # sleep 15

# if [[ $BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED = "true" ]]; then
#     lxc exec cachestack -- mkdir -p cachestack/apps/bitcoind/data

#     # if the directory exists, then we're good to go.
#     if [ -d "$BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED_SOURCEDIR" ]; then
    
#         # TODO ugprade basic authentication to SSH keys
#         echo "$BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED_SOURCEDIR on $HOSTNAME will be pushed to cachestack rsyncd."
#         SSH_KEY_PATH="~/.bcm/endpoints/lexx/.ssh/cachestack-rsync-key"

#         rsync -av -e "ssh -i $SSH_KEY_PATH -p 2222 -l rsync -o StrictHostKeyChecking=no" $BCS_INSTALL_BITCOIND_TESTNET_RSYNC_SEED_SOURCEDIR/ cachestack.lxd:bitcoind_testnet_data
#     fi
# fi
