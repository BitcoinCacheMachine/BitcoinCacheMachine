#!/bin/bash



export BCM_DEBUG=1

bcm init --cert-name="BCM backup/recovery" --cert-username="username" --cert-fqdn="domain.com"

# create a multipass cluster with mgmt on localnet
bcm cluster create -c=dev -t=multipass -x=net -l=3
bcm cluster destroy -c=dev


# create a cluster named dev. LXD is deployed to localhost
bcm cluster create --cluster-name="dev" --provider="baremetal" --mgmt-type="local"
bcm cluster destroy --cluster-name=dev


bcm init -n=test -u=ubuntu -c=domain.com

# create a 3 node multipass cluster locally.
bcm cluster create -c=home -t=multipass -l=3 -x=net


## BCM PROJECT

# Create
bcm project create --user-name=


## File operations



bcm file encrypt --file-path="$BCM_RUNTIME_DIR/test/test.txt" --cert-dir="$BCM_RUNTIME_DIRcerts"