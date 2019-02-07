#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# removes the current project from the active cluster.
bcm project remove 
#--del-template --del-lxcbase

# destroys the active cluster
bcm cluster destroy --ssh-username="$(whoami)" --ssh-hostname="$(hostname)"

# deletes certificates
bcm reset