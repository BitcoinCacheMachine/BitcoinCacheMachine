#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

docker stack deploy -c ./bitcoinstack.yml bitcoinstack
