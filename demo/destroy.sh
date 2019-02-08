#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

#bcm stack remove ...
#bcm stack remove ...
#bcm stack remove ...


# removes the current project from the active cluster.
bcm deprovision --del-template --del-lxcbase

# destroys the active cluster unless --cluster-name is specified.
bcm cluster destroy --ssh-username="$(whoami)" --ssh-hostname="$(hostname)"

# deletes certificates
bcm reset