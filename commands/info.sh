#!/bin/bash

set -Eeuo pipefail

BCM_CERT_NAME=
BCM_CERT_USERNAME=
BCM_CERT_HOSTNAME=
DEFAULT_KEY_ID=

echo "bcm_client:"
echo "  client_version:            $BCM_VERSION"

if [[ -d $GNUPGHOME ]]; then
    echo "  cert_dir:                  $GNUPGHOME"
    
    if [[ -f "$GNUPGHOME/env" ]]; then
        # shellcheck disable=SC1090
        source "$GNUPGHOME/env"
        BCM_CERT_NAME="$BCM_CERT_NAME"
        BCM_CERT_USERNAME="$BCM_CERT_USERNAME"
        BCM_CERT_HOSTNAME="$BCM_CERT_HOSTNAME"
        DEFAULT_KEY_ID="$DEFAULT_KEY_ID"
        echo "    default_key_id:             $DEFAULT_KEY_ID"
        echo "    default_cert_title:         $BCM_CERT_NAME <$BCM_CERT_USERNAME@$BCM_CERT_HOSTNAME>"
    fi
fi

if [[ -d $PASSWORD_STORE_DIR ]]; then
    echo "  password_dir:              $PASSWORD_STORE_DIR"
fi

if [[ -d $BCM_SSH_DIR ]]; then
    echo "  ssh_dir:                   $BCM_SSH_DIR"
fi

if [ ! -z ${BCM_DEBUG+x} ]; then
    echo "  bcm_debug_mode:            $BCM_DEBUG"
fi

echo "  active_ssh_endpoint:       $BCM_SSH_HOSTNAME"
echo "  active_ssh_user:           $BCM_SSH_USERNAME"
echo "  target_project:            $BCM_PROJECT"
echo "  target_chain:              $BCM_ACTIVE_CHAIN"
