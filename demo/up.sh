#!/bin/bash

set -Eeuo pipefail

# Init your SDN controller; create a new GPG certificate 'Satoshi Nakamoto satoshi@bitcoin.org'
bcm init --cert-name="Satoshi Nakamoto" --username="satoshi" --hostname="bitcoin.org"

# deploy to your localhost running on baremetal
bcm cluster create --cluster-name="LocalCluster" --ssh-username="$(whoami)" --ssh-hostname="$(hostname)"

# deploy to a hardware-enforced VM reachable by your SDN controller.
bcm cluster create --driver=multipass --cluster-name="bcm-multipass"

# deploy components
bcm stack deploy bitcoind --chain=testnet
bcm stack deploy clightning --chain=testnet

# some ENV VARS that are useful for development
#export BCM_DEBUG=1
#export DOCKER_IMAGE_CACHE="cachestack.domainname.tld"
