#!/bin/bash

set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# load the environment variables for the current LXD remote.
source ~/.bcm/bcm_env.sh

#echo "Destrying elastic stuff"
#c/down_elastic.sh


echo "Destroying lxd host bitcoin"
./bitcoin/down_bitcoin.sh


echo "Destroying manager1 lxd host and associated lxd components."
./managers/down_managers.sh

