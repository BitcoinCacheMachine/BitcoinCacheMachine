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

  #TODO check to ensure the the macvlan interface is set.
  bash -c ./bcs/up_lxd.sh
  exit
fi


# else



#   echo "Installing Bitcoin Cache Machine proper. A local Cache Stack will be deployed.


#   echo "Clearing LXD http proxy settings. Bitcoin Cache Stack will download from the Internet."
#   lxc config set core.proxy_https ""
#   lxc config set core.proxy_http ""
#   lxc config set core.proxy_ignore_hosts ""

#   # Create a docker host template if it doesn't exist already
#   if [[ -z $(lxc list | grep dockertemplate) ]]; then
#     export BC_ZFS_POOL_NAME="bcs_data"
#       # Create a docker host template if it doesn't exist already
#     if [[ -z $(lxc list | grep $BC_ZFS_POOL_NAME) ]]; then
#       # create the host template if it doesn't exist already.
#       bash -c ./host_template/up_lxd.sh
#     fi

#     # if the template doesn't exist, publish it create it.
#     if [[ -z $(lxc image list | grep bctemplate) ]]; then
#       echo "Publishing dockertemplate/dockerSnapshot snapshot as bctemplate lxd image."
#       lxc publish $(lxc remote get-default):dockertemplate/dockerSnapshot --alias bctemplate
#     fi    
#   else
#     echo "Skipping creation of the host template. Snapshot already exists."
#   fi  

#   echo "Calling Bitcoin Cache Stack Installation Script."
#   bash -c ./bcs/up_lxd.sh
# fi