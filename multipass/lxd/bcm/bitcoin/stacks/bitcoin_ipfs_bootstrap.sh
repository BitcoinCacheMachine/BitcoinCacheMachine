#!/bin/bash

# this script is meant to be executed on the LXD host bitcoin

# quit if there's an error
set -e

# this volume holds all bitcoind blockchain data.
docker volume create bitcoind-data

# download via IPFS a fully indexed copy of the blockchain data
if [[ $BCM_BITCOIN_IPFS_BOOTSTRAP = "true" ]]; then
  echo "Bootstrapping Bitcoin Data directory via IPFS."
  docker run -d -v ipfsdata:/data/ipfs -e IPFS_PATH=/data/ipfs ipfs/go-ipfs:latest
  wait-for-it -t 0 

else
  echo "Bitcoin Data directory will be downloaded via bitcoind."
fi
