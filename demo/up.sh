#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# This script is a sample BCM CLI program that instantiates
# a datacenter stack on a single computer (thus no fault tolerance)
# First, the SDN Controller is initialized with 'bcm init'
# Second, a new BCM project is defined. The first and second steps require
# Trezor.

source "$BCM_GIT_DIR/.env"

# run bcm init
bcm init \
	--name="BCM" \
	--username="$BCM_CERT_USERNAME" \
	--hostname="$BCM_CERT_HOSTNAME"

# ## Create a basic project definition.
bcm project create --project-name="$BCM_PROJECT_NAME"

# create a cluster named dev. LXD is deployed to localhost
bcm cluster create \
	--cluster-name="$BCM_CLUSTER_NAME" \
	--provider="local"

bcm cluster create --cluster-name=meetup \
	--provider=local

# then deploy that project definition to an existing cluster.
bcm project deploy \
	--project-name="$BCM_PROJECT_NAME" \
	--cluster-name="$BCM_CLUSTER_NAME" \
	--user-name="$BCM_PROJECT_USERNAME"
