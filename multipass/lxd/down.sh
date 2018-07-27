#!/bin/bash

# stop script if error is encountered.
#set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# quit if there are no BC environment variables
if [[ -z $(env | grep BC) ]]; then
  echo "BC variables not set. Please source ~/.bcm/lxd_endpoints.sh"
  exit
fi

# get or update the BCM host template git repo
if [[ $BC_CACHESTACK_STANDALONE = "true" ]]; then
  echo "Calling Bitcoin Cache Machine destruction script."
  bash -c ./bcs/down_lxd.sh
else
  echo "Calling Bitcoin Cache Machine down script."
  bash -c ./bcm/down_lxd.sh

  echo "Calling Bitcoin Cache Machine Cache Stack down script."
  bash -c ./bcs/down_lxd.sh
fi



# bctemplate
if [[ $BC_LXD_IMAGE_BCTEMPLATE_DELETE = 'true' ]]; then
  if [[ $(lxc image list | grep bctemplate) ]]; then
    echo "Destrying lxd image 'bctemplate'."
    lxc image delete bctemplate
  fi
fi

