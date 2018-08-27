#!/bin/bash

set -e

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# call bcm_script_before.sh to perform the things that every BCM script must do prior to proceeding
bash -c $BCM_LOCAL_GIT_REPO/resources/bcm/bcm_script_before.sh

# if bcm-template lxc image exists, run the gateway template creation script.
if [[ -z $(lxc image list | grep "bcm-template") ]]; then
    echo "Required LXC image 'bcm-template' does not exist! Ensure your current LXD remote $(lxc remote get-default) creates or downloads a remote 'bcm-template'."
    exit 1
fi


# create and populate the required networks
bash -c ./create_lxd_gateway_networks.sh

# create an populate necessary profiles
bash -c ./create_lxd_gateway_profiles.sh

# let's generate a LXC template to base our LXD container on.
bash -c ./create_lxd_gateway-template.sh

# create the docker back for 'bcm-gateway'
bash -c "../shared/create_dockervol.sh bcm-gateway"

# deploy the actual deploy_lxd_gateway instance
bash -c ./deploy_lxd_gateway.sh