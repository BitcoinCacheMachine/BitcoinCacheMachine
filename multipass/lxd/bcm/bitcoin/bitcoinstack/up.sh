#!/bin/bash

set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

docker stack deploy -c btcstack.yml btcstack
