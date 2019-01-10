#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# This script is written for demo purposes.
source "$BCM_GIT_DIR/.env"

# run bcm init
bcm init --name="$BCM_CERT_NAME" \
	--username="$BCM_CERT_USERNAME" \
	--hostname="$BCM_CERT_HOSTNAME"

# Create a basic project definition.
bcm project create --project-name="$BCM_PROJECT_NAME"

# new cluster based on existing SSH endpoint.
bcm cluster create --cluster-name="$BCM_CLUSTER_NAME" \
	--provider=ssh \
	--ssh-hostname="$BCM_CLUSTER_SSH_ENDPOINT_NAME" \
	--lxd-hostname="$BCM_CLUSTER_LXD_ENDPOINT_NAME"

# then deploy that project definition to an existing cluster.
bcm project deploy \
	--project-name="$BCM_PROJECT_NAME" \
	--cluster-name="$BCM_CLUSTER_NAME" \
	--user-name="$BCM_PROJECT_USERNAME"
