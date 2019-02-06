#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# removes the current project from the active cluster.
bcm project remove

# destroys the active cluster
bcm cluster destroy --ssh-username="ubuntu" --ssh-hostname="antsle"

# deletes certificates
bcm reset