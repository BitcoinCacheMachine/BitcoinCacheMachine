#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

source ./.env 
 
# This script is a sample BCM CLI program that instantiates 
# a datacenter stack. First, the SDN Controller is initialized
# then a 4 node cluster is created using multipass. 
# next a default project scadffolding is created
# Then we deploy the project definition to the cluster we created.


bcm init --cert-name="derek" --cert-username="$BCM_CERT_USERNAME" --cert-fqdn="$BCM_CERT_HOSTNAME"

# create a cluster named dev. LXD is deployed to localhost
bcm cluster create --cluster-name="$BCM_CLUSTER_NAME" --provider="multipass" --mgmt-type="local" --node-count=3
# --node-count=2

## Create a basic project difintion.
bcm project create --project-name="$BCM_PROJECT_NAME"

# then deploy that project definition to an existing cluster.
bcm project deploy --project-name="$BCM_PROJECT_NAME" --cluster-name="$BCM_CLUSTER_NAME" --user-name="$BCM_PROJECT_USERNAME"