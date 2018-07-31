#!/bin/bash

set -e

echo "Building and pushing farscapian/bitcoind:16.1 to DockerHub."
#this step prepares custom images
docker build -t farscapian/bitcoind:16.1 .
docker push farscapian/bitcoind:16.1
