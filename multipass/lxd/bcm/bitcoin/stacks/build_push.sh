#!/bin/bash

set -e

# echo "Building and pushing lnd."
# #this step prepares custom images
# docker build -t farscapian/lnd:latest ./lnd/
# docker push farscapian/lnd:latest

# # echo "Building and pushing lncli-web."
# # # adds start script for waiting on lnd rpc to come online
# docker build -t farscapian/lncliweb:latest ./lncliweb/
# docker push farscapian/lncliweb:latest




# # echo "Building and pushing lightningd / lightningd."
# docker build -t farscapian/lightningd:latest ./lightningd/
# docker push farscapian/lightningd:latest

# echo "Building and pushing bitcoin streams app."
# docker build -t farscapian/bitcoinstreams:latest ./streams/
# docker push farscapian/bitcoinstreams:latest

