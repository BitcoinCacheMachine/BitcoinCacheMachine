# #!/bin/bash

# echo "Starting /app/bitcoin/bitcoin-entrypoint.sh"

# # set the working directory to the location where the script is located
# cd "$(dirname "$0")"

# source ./environment

# if [[ $(env | grep BCM) = '' ]] 
# then
#   echo "BCM variables not set.  Please source a .env file."
#   exit 1
# fi

# docker pull ipfs/go-ipfs:latest

# docker volume create bitcoind-$BCM_BITCOIN_CHAIN-data
# docker volume create ipfsdata

# docker run -d --name bootstrapper -v bitcoind-$BCM_BITCOIN_CHAIN-data:/bitcoindata -v ipfsdata:/data/ipfs ipfs/go-ipfs:latest daemon

# sleep 20



# sleep 10 

# docker kill bootstrapper
