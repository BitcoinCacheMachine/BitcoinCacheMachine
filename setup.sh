#!/bin/bash

# This script iniitalizes the management computer that is executing 
# BCM-related LXD and multipass scripts against (local) or remote LXD
# endpoints.

# quit if there's an error
set -e

# if ~/.bcm doesn't exist, create and populate it with default .env files.
if [ ! -d "~/.bcm" ]; then
  echo "Bitcoin Cache Machine config directory exists at ~/.bcm"
else
  echo "Creating Bitcoin Cache Machine config directory at ~/.bcm"
  mkdir -p ~./bcm

  #cp ./resources/.bcm/lxd_endpoints.sh ~/.bcm/lxd_endpoints.sh
  #cp ./resources/.bcm/llxd_env.sh ~/.bcm/lxd.env.sh
fi
