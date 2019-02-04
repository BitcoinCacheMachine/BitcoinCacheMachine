#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# destroys the active cluster
bcm cluster destroy --ssh-username="$(whoami)" --ssh-hostname="$(hostname)"

# deletes certificates
bcm reset