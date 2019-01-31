#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=SC1090
source "$BCM_GIT_DIR/env"

if [[ -d $GNUPGHOME ]]; then
    if [[ $GNUPGHOME != "$HOME/.gnupg" ]]; then
        echo "Deleting $GNUPGHOME."
        sudo rm -Rf "$GNUPGHOME"
    fi
fi

if [[ -d $PASSWORD_STORE_DIR ]]; then
    if [ "$PASSWORD_STORE_DIR" != "$HOME/.password_store" ]; then
        echo "Deleting $PASSWORD_STORE_DIR."
        sudo rm -Rf "$PASSWORD_STORE_DIR"
    fi
fi

bash -c "$BCM_GIT_DIR/cli/tmp_down.sh"
sudo snap remove lxd