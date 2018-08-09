#!/bin/bash

# This script iniitalizes the management computer that is executing 
# BCM-related LXD and multipass scripts against (local) or remote LXD
# endpoints.

# quit if there's an error
set -e

# install LXD on the admin machine.
sudo apt update && sudo apt install -y zfsutils-linux wait-for-it lxd rsync

# if ~/.bcm doesn't exist, create and populate it with default .env files.
if [ ! -d ~/.bcm ]; then
  echo "Creating Bitcoin Cache Machine config directory at ~/.bcm"
  mkdir -p ~/.bcm
else
  echo "Bitcoin Cache Machine config directory exists at ~/.bcm"
fi

# if ~/.bcm/endpoints doesn't exist, create and populate it with default .env files.
if [ ! -d ~/.bcm/endpoints ]; then
  echo "Creating BCM endpoints directory at ~/.bcm/endpoints"
  mkdir -p ~/.bcm/endpoints
  touch ~/.bcm/endpoints/local.env
else
  echo "BCM endpoints config directory exists at ~/.bcm/endpoints"
fi

# if ~/.bcm/runtime doesn't exist create it
if [ ! -d ~/.bcm/runtime ]; then
  echo "Creating BCM runtime directory at ~/.bcm/runtime"
  mkdir -p ~/.bcm/runtime
else
  echo "BCM runtime directory exists at ~/.bcm/runtime"
fi

# if ~/.bcm/scripts doesn't exist create it
if [ ! -d ~/.bcm/scripts ]; then
  echo "Creating BCM scripts directory at ~/.bcm/scripts"
  mkdir -p ~/.bcm/scripts
else
  echo "BCM scripts directory exists at ~/.bcm/scripts"
fi


# copy defaults.env to ~/.bcm/defaults.evn if it doesn't exist.
if [ ! -f ~/.bcm/defaults.env ]; then
  echo "Copying defaults.env to ~/.bcm/defaults.env"
  cp ./resources/defaults.env ~/.bcm/defaults.env
fi

