#!/bin/bash

# Init your SDN controller; create a new GPG certificate 'Satoshi Nakamoto satoshi@bitcoin.org'
bcm init --cert-name="Satoshi Nakamoto" --username="satoshi" --hostname="bitcoin.org"

# deploy to your localhost running on baremetal
# bcm cluster create --cluster-name="LocalCluster" --ssh-username="$(whoami)" --ssh-hostname="$(hostname)"

# deploy to a hardware VM hosted on your SDN controller.
bcm cluster create --driver=multipass --cluster-name=derek

# deploy bcm components
bcm stack deploy clightning --chain=testnet
bcm stack deploy bitcoind --chain=testnet
