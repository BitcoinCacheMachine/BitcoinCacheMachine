#!/usr/bin/env bash

set -eu
cd "$(dirname "$0")"

# quit if there are no BCM environment variables
if [[ -z $(env | grep BCM) ]]; then
  echo "BCM variables not set. Please source BCM environment variables."
  exit
fi

# echo "Calling ./app_hosts/destroy_lxc_apphosts.sh"
# bash -c "./bcmnet/app_hosts/destroy_lxc_apphosts.sh template"

# echo "Calling ./bcmnet/destroy_lxc_bcmnet.sh"
# bash -c "./bcmnet/destroy_lxc_bcmnet.sh template"

echo ""
echo "Calling ./bcm_core/destroy_lxc_gateway.sh"
./bcm_core/destroy_lxc_gateway.sh

echo "Calling ./host_template/destroy_lxc_host_template.sh"
./host_template/destroy_lxc_host_template.sh

# ensure we have an LXD project defined for this deployment
# you can use lxd projects to deploy mutliple BCM instances on the same set of hardware (i.e., lxd cluster)
if [[ $(lxc project list | grep "$BCM_PROJECT_NAME") ]]; then
  lxc project switch default
  lxc project delete $BCM_PROJECT_NAME
fi


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

