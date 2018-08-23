#!/bin/bash

set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

echo "Destroying lxd host bitcoin"
bash -c ./bitcoin/down_bitcoin.sh

echo "Destroying manager1 lxd host and associated lxd components."
bash -c ./managers/down_lxd_managers.sh
