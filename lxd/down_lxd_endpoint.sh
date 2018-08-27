#!/bin/bash

# call bcm_script_before.sh to perform the things that every BCM script must do prior to proceeding
bash -c $BCM_LOCAL_GIT_REPO/resources/bcm/bcm_script_before.sh

# quit if there are no BCM environment variables
if [[ -z $(env | grep BCM) ]]; then
  echo "BCM variables not set. Please source BCM environment variables."
  exit
fi

# if [[ $BCM_BITCOIN_DELETE = "true" ]]; then
#   echo "Calling ./bitcoin/down_lxd_bitcoin.sh"
#   bash -c ./bitcoin/down_lxd_bitcoin.sh
# else
#   echo "BCM environment variables are configured to SKIP deletion of LXD host 'bitcoin'."
# fi

# if [[ $BCM_MANAGERS_DELETE = "true" ]]; then
#   echo "Calling ./managers/down_lxd_managers.sh"
  # bash -c ./managers/down_lxd_managers.sh
# else
#   echo "BCM environment variables are configured to SKIP deletion of LXD 'manager' hosts."
# fi

# if [[ $BCM_CACHESTACK_DELETE = "true" ]]; then
#   echo "Calling ./cachestack/down_lxd_cachestack.sh"
  # bash -c ./cachestack/down_lxd_cachestack.sh
# else
#   echo "BCM environment variables are configured to SKIP deletion of LXD host 'cachestack'."
# fi

# if [[ $BCM_GATEWAY_DELETE = "true" ]]; then
echo "Calling ./gateway/down_lxd_gateway.sh"
bash -c ./gateway/down_lxd_gateway.sh
# else
#   echo "BCM environment variables are configured to SKIP deletion of LXD host 'gateway'."
# fi

# # if set, we run the host_template down scripts.
# if [[ $BCM_ADMIN_HOST_TEMPLATE_DELETE = "true" ]]; then
echo "Calling ./host_template/down_lxd_host_template.sh"
bash -c ./host_template/down_lxd_host_template.sh
# else
#   echo "BCM environment variables are configured to SKIP deletion of the BCM host template."
# fi

# delete lxd network lxdbrBCMCSBrdg 
if [[ $(lxc network list | grep lxdbrBCMCSBrdg) ]]; then
    echo "Deleting lxd network 'lxdbrBCMCSBrdg'."
    lxc network delete lxdbrBCMCSBrdg
fi
