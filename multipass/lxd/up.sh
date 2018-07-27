#!/bin/bash

# stop scrtip if error is encountered.
set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# quit if there are no BC environment variables
if [[ -z $(env | grep BC) ]]; then
  echo "BC variables not set. Please source ~/.bcm/lxd_endpoints.sh"
  exit
fi


# Installation branching logic. 
if [[ $BC_CACHESTACK_STANDALONE="true" ]]; then
  echo "Performing a Cache Stack standalone installation."
  echo "Installing Bitcoin Cache Stack in standalone mode. Cache Stack will attach to physical interface $BCS_TRUSTED_HOST_INTERFACE".

  #TODO check to ensure the the macvlan interface is set.
  bash -c ./bcs/up_lxd.sh
  exit
fi

# # create the lxdbrCacheStack network if it doesn't exist.
# if [[ -z $(lxc network list | grep lxdbrCacheStack) ]]; then
#   # lxdbrCacheStack is used to connect the Cache Stack and the Bitcoin Cache Machine components.
#   lxc network create lxdbrCacheStack ipv4.nat=false
  
#   #TODO check to ensure the the macvlan interface is set.
#   bash -c ./bcs/up_lxd.sh
# else
#   echo "lxdbrCacheStack already exists."
# fi

# # else



#   echo "Installing Bitcoin Cache Machine proper. A local Cache Stack will be deployed.


#   echo "Clearing LXD http proxy settings. Bitcoin Cache Stack will download from the Internet."
#   lxc config set core.proxy_https ""
#   lxc config set core.proxy_http ""
#   lxc config set core.proxy_ignore_hosts ""
