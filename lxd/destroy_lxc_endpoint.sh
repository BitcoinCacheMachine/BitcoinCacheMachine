#!/bin/bash

set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# call bcm_script_before.sh to ensure we have up-to-date ENV variables.
source "$BCM_LOCAL_GIT_REPO/resources/export_bcm_envs.sh"

# quit if there are no BCM environment variables
if [[ -z $(env | grep BCM) ]]; then
  echo "BCM variables not set. Please source BCM environment variables."
  exit
fi

# echo "Calling ./app_hosts/destroy_lxc_apphosts.sh"
# bash -c "./bcmnet/app_hosts/destroy_lxc_apphosts.sh template"

# echo "Calling ./bcmnet/destroy_lxc_bcmnet.sh"
# bash -c "./bcmnet/destroy_lxc_bcmnet.sh template"

# echo "Calling ./gateway/destroy_lxc_gateway.sh"
# bash -c "./gateway/destroy_lxc_gateway.sh template"

echo "Calling ./host_template/destroy_lxc_host_template.sh"
bash -c "./host_template/destroy_lxc_host_template.sh"

# ensure we have an LXD project defined for this deployment
# you can use lxd projects to deploy mutliple BCM instances on the same set of hardware (i.e., lxd cluster)
if [[ $(lxc project list | grep bcm) ]]; then
  lxc project switch default
  lxc project delete bcm
fi

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

