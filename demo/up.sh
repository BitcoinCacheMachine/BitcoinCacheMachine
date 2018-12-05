#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source ./.env
 
# This script is a sample BCM CLI program that instantiates 
# a datacenter stack on a single computer (thus no fault tolerance)
# First, the SDN Controller is initialized with 'bcm init'
# Second, a new BCM project is defined. The first and second steps require
# Trezor.

# Next, a 3 node cluster is created using multipass. Running BCM using multipass 
# is for development and DOES NOT PROVIDE fault tolerance. 
# Next, a default project created with 'bcm project create'.
# Finally, we deploy the project definition to the cluster we created.

# run bcm init
bcm init --cert-name="alice" --cert-username="$BCM_CERT_USERNAME" --cert-fqdn="$BCM_CERT_HOSTNAME" --runtime-dir="$HOME/protected/.bcm"

## Create a basic project difintion.
bcm project create --project-name="$BCM_PROJECT_NAME"

# create a cluster named dev. LXD is deployed to localhost
# Use 'provider=baremetal' to install locally (recommended for production)
bcm cluster create --cluster-name="$BCM_CLUSTER_NAME" --provider="baremetal" --mgmt-type="local" --node-count=3

# then deploy that project definition to an existing cluster.
bcm project deploy --project-name="$BCM_PROJECT_NAME" --cluster-name="$BCM_CLUSTER_NAME" --user-name="$BCM_PROJECT_USERNAME"