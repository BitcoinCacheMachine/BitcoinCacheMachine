#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

export BCM_DEBUG=1
export BCM_CACHESTACK="192.168.1.123" # must be a DNS or IP address -- not avahi name

# Init your SDN controller; create a new GPG certificate 'Satoshi Nakamoto satoshi@bitcoin.org'
bcm init --cert-name="Satoshi Nakamoto" --username="satoshi" --hostname="bitcoin.org"

# Create a new BCM cluster master on your localhost.
bcm cluster create --cluster-name="AntsleCluster" --ssh-username="ubuntu" --ssh-hostname="antsle"

# Create a new BCM project specification
#bcm project create --project-name="name"

# The default BCM project BCMBase is deployed when --project-name is left unspecified.
# all project deployments are applied to the active BCM cluster unless specified otherwise.
bcm project deploy