#!/bin/bash

set -Eeuo pipefail

echo "BCM Runtime:"
echo "  BCM_TARGET_VERSION:        $BCM_VERSION"
echo "  GNUPGHOME:                 $GNUPGHOME"
echo "  DEFAULT_KEY_ID:            $DEFAULT_KEY_ID"

if [[ -d $PASSWORD_STORE_DIR ]]; then
    echo "  PASSWORD_STORE_DIR:        $PASSWORD_STORE_DIR"
fi

if [[ -d $BCM_SSH_DIR ]]; then
    echo "  BCM_SSH_DIR:               $BCM_SSH_DIR"
fi

echo "  BCM_DEBUG:                 $BCM_DEBUG"
echo "  BCM_SSH_HOSTNAME:          $BCM_SSH_HOSTNAME"
echo "  BCM_SSH_USERNAME:          $BCM_SSH_USERNAME"
echo "  BCM_DATACENTER:            $BCM_DATACENTER"
echo "  BCM_PROJECT:               $BCM_PROJECT"
echo "  BCM_ACTIVE_CHAIN:          $BCM_ACTIVE_CHAIN"
