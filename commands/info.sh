#!/bin/bash

set -Eeuo pipefail

BCM_CERT_NAME=
BCM_CERT_USERNAME=
BCM_CERT_HOSTNAME=
DEFAULT_KEY_ID=

echo "bcm_client:"
echo "  client_version:            $BCM_VERSION"

if [[ -d $GNUPGHOME ]]; then
    echo "  cert_dir:                  $GNUPGHOME/trezor"
    
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

echo "bcm_env:"
echo "  BCM_DEBUG:                 $BCM_DEBUG"
echo "  BCM_SSH_HOSTNAME:          $BCM_SSH_HOSTNAME"
echo "  BCM_SSH_USERNAME:          $BCM_SSH_USERNAME"
echo "  BCM_PROJECT:               $BCM_PROJECT"
echo "  BCM_ACTIVE_CHAIN:          $BCM_ACTIVE_CHAIN"
