#!/bin/bash

set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# call bcm_script_before.sh to perform the things that every BCM script must do prior to proceeding
#bash -c $BCM_LOCAL_GIT_REPO/resources/bcm/bcm_script_before.sh

# quit if there are no BCM environment variables
if [[ -z $(env | grep BCM) ]]; then
  echo "BCM variables not set. Please source BCM environment variables."
  exit
fi

echo "Calling ./app_hosts/destroy_lxc_apphosts.sh"
bash -c "./app_hosts/destroy_lxc_apphosts.sh template"

echo "Calling ./bcmnet/destroy_lxc_bcmnet.sh"
bash -c "./bcmnet/destroy_lxc_bcmnet.sh template"

echo "Calling ./gateway/destroy_lxc_gateway.sh"
bash -c "./gateway/destroy_lxc_gateway.sh template"

echo "Calling ./host_template/destroy_lxc_host_template.sh"
bash -c "./host_template/destroy_lxc_host_template.sh"

rm -rf ~/.bcm/runtime/$(lxc remote get-default)/


# if [[ $BCM_BITCOIN_DELETE = "true" ]]; then
#   echo "Calling ./bitcoin/destroy_lxd_bitcoin.sh"
#   bash -c ./bitcoin/destroy_lxd_bitcoin.sh
# else
#   echo "BCM environment variables are configured to SKIP deletion of LXD host 'bitcoin'."
# fi

# if [[ $BCM_MANAGERS_DELETE = "true" ]]; then
#   echo "Calling ./managers/destroy_lxd_managers.sh"
  # bash -c ./managers/destroy_lxd_managers.sh
# else
#   echo "BCM environment variables are configured to SKIP deletion of LXD 'manager' hosts."
# fi

