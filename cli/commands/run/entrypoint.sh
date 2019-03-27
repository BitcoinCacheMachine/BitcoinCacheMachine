#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_CLI_VERB=${2:-}
if [ -z "${BCM_CLI_VERB}" ]; then
    echo "Please provide a BCM 'run' command."
    cat ./help.txt
    exit
fi

if [[ $BCM_CLI_VERB == "electrum" ]]; then
    bash -c "$BCM_GIT_DIR/controller/stacks/electrum/up.sh"
fi

