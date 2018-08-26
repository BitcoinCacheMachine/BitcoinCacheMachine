#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# prepare the the underlay-template snapshot
bash -c ./create_lxd_underlay-template.sh

# deploy the actual underlay instance
bash -c ./deploy_lxd_underlay.sh