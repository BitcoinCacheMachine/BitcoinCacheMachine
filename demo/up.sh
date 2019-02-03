#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# This script is written for demo purposes.
source "$BCM_GIT_DIR/env"

#run bcm init
bcm init --name="$BCM_CERT_NAME" \
--username="$BCM_CERT_USERNAME" \
--hostname="$BCM_CERT_HOSTNAME"

# new cluster based on existing SSH endpoint.
bcm cluster create --cluster-name="$BCM_CLUSTER_NAME" \
--ssh-username="$BCM_SSH_USERNAME" \
--ssh-hostname="$BCM_SSH_HOSTNAME"

# then deploy that project definition to an existing cluster.
bcm project deploy --cluster-name="$BCM_CLUSTER_NAME"