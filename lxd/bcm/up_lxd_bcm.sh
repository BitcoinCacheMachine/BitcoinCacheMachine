#!/bin/bash

# exit script if there's an error anywhere
set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# quit if the BCM environment variables havne't been loaded.
if [[ $(env | grep BCM) = '' ]]; then
  echo "BCM variables not set. Please source a .env file."
  exit 1 
fi

# a manager is required for each BCM instance.
# TODO add more managers across independent hardware
echo "Creating manager host(s)."
bash -c ./managers/up_managers.sh

echo "Waiting for the GELF listener to come online."
lxc exec manager1 -- wait-for-it -t 0 10.0.0.11:12201


# Bitcoin infrastructure is required. Will probably implement some kind of primary/backup
# configuration for the trusted bitcoin full node.
echo "Calling up_bitcoin.sh."
./bitcoin/up_bitcoin.sh

