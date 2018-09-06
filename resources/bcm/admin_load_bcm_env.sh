#!/bin/bash

#echo "Sourcing all BCM default environment variables located in $BCM_LOCAL_GIT_REPO/resources/defaults/"

BCM_DEFAULTS_DIR="$BCM_LOCAL_GIT_REPO/resources/bcm/defaults"

source $BCM_DEFAULTS_DIR/defaults.env
source $BCM_DEFAULTS_DIR/gateway.env
source $BCM_DEFAULTS_DIR/managers.env
source $BCM_DEFAULTS_DIR/bitcoin.env

BCM_ACTIVE_LXD_ENDPOINT=$(lxc remote get-default)

# if ~/.bcm/endpoints/$BCM_ACTIVE_LXD_ENDPOINT.env exists, source it
if [[ -e ~/.bcm/endpoints/$BCM_ACTIVE_LXD_ENDPOINT.env ]]; then
    #echo "Sourcing ~/.bcm/endpoints/$BCM_ACTIVE_LXD_ENDPOINT.env."
    source ~/.bcm/endpoints/$BCM_ACTIVE_LXD_ENDPOINT.env
else
    echo "~/.bcm/endpoints/$BCM_ACTIVE_LXD_ENDPOINT.env does not exist! Stubbing one out for you bro."
    touch ~/.bcm/endpoints/$BCM_ACTIVE_LXD_ENDPOINT.env

    echo '#!/bin/bash' >> ~/.bcm/endpoints/$BCM_ACTIVE_LXD_ENDPOINT.env
    BCM_LXD_SECRET=$(apg -n 1 -m 30 -M CN)
    echo 'export BCM_LXD_SECRET="'$BCM_LXD_SECRET'"' >> ~/.bcm/endpoints/$BCM_ACTIVE_LXD_ENDPOINT.env
fi