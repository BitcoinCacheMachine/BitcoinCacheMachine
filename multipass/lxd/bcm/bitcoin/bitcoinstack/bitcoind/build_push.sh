#!/bin/bash

set -e

echo "Building and pushing bitcoind."
#this step prepares custom images
docker build -t farscapian/bitcoind:latest .
docker push farscapian/bitcoind:latest
