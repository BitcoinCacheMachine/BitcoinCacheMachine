#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# This script is written for demo purposes.
source "$BCM_GIT_DIR/.env"
source ./meetup.env

# run bcm init
bcm init --cert-name="BCM" \
	--cert-username="$BCM_CERT_USERNAME" \
	--cert-fqdn="$BCM_CERT_HOSTNAME"

# Create a basic project definition.
bcm project create --project-name="$BCM_PROJECT_NAME"

# new cluster based on existing SSH endpoint.
bcm cluster create --cluster-name=meetup --provider=ssh --hostname=lexx

# then deploy that project definition to an existing cluster.
bcm project deploy \
	--project-name="$BCM_PROJECT_NAME" \
	--cluster-name="$BCM_CLUSTER_NAME" \
	--user-name="$BCM_PROJECT_USERNAME"
