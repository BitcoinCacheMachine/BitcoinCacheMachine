#!/bin/bash

lxc exec manager1 -- bash -c /apps/bitcoin/down.sh

lxc delete --force bitcoin >/dev/null

lxc profile delete bitcoinprofile >/dev/null

lxc network delete lxdbrBitcoin

# wait for the node to go down them remove the node from the stack
lxc exec manager1 -- docker node rm bitcoin

lxc storage delete bitcoin-dockervol
