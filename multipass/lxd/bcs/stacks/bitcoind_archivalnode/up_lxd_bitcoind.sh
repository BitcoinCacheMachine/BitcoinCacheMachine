#!/bin/bash


# TODO refactor to subdirectory
echo "Deploying a bitcoind archival node to the Cache Stack."
lxc exec cachestack -- mkdir -p /apps/bitcoind_archivalnode
lxc file push ./stacks/bitcoind_archivalnode/bitcoind.yml cachestack/apps/bitcoind_archivalnode/bitcoind.yml
lxc file push ./stacks/bitcoind_archivalnode/bitcoind-testnet.conf cachestack/apps/bitcoind_archivalnode/bitcoind-testnet.conf
lxc file push ./stacks/bitcoind_archivalnode/bitcoind-torrc.conf cachestack/apps/bitcoind_archivalnode/bitcoind-torrc.conf
lxc exec cachestack -- docker stack deploy -c /apps/bitcoind_archivalnode/bitcoind.yml bitcoind