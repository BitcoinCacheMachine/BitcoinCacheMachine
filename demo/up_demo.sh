#!/bin/bash

set -eu
cd "$(dirname "$0")"
source ./env.sh

bcm init --cert-name="derek" --cert-username="$BCM_CERT_USERNAME" --cert-fqdn="$BCM_CERT_HOSTNAME"

# create a cluster named dev. LXD is deployed to localhost
bcm cluster create --cluster-name="$BCM_CLUSTER_NAME" --provider="baremetal" --mgmt-type="local"

# bcm cluster create --cluster-name="$BCM_CLUSTER_NAME" --provider="multipass" --mgmt-type="local" --node-count=3
# bcm cluster destroy --cluster-name="$BCM_CLUSTER_NAME"


## Create a basic project difintion.
bcm project create --project-name="$BCM_PROJECT_NAME"

# then deploy that project definition to an existing cluster.
bcm project deploy --project-name="$BCM_PROJECT_NAME" --cluster-name="$BCM_CLUSTER_NAME" --user-name="$BCM_PROJECT_USERNAME"
# 

## File operations



#bcm file encrypt --file-path="$BCM_RUNTIME_DIR/test/test.txt" --cert-dir="$BCM_RUNTIME_DIRcerts"