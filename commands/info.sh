#!/bin/bash

set -Eeuo pipefail

echo "BCM ENVIRONMENT:"
echo "  BCM_TARGET_VERSION:        $BCM_VERSION"
echo "  GNUPGHOME:                 $GNUPGHOME"
echo "  DEFAULT_KEY_ID:            $DEFAULT_KEY_ID"

if [[ -d $PASSWDHOME ]]; then
    echo "  PASSWDHOME:        $PASSWDHOME"
fi

if [[ -d $SSHHOME ]]; then
    echo "  SSHHOME:               $SSHHOME"
fi
echo "  BCM_BOOTSTRAP_DIR:         $BCM_BOOTSTRAP_DIR"
echo "  BCM_DEBUG:                 $BCM_DEBUG"
echo "  BCM_SSH_HOSTNAME:          $BCM_SSH_HOSTNAME"
echo "  BCM_SSH_USERNAME:          $BCM_SSH_USERNAME"
echo "  BCM_DATACENTER:            $BCM_DATACENTER"
echo "  BCM_PROJECT:               $BCM_PROJECT"
echo "  BCM_ACTIVE_CHAIN:          $BCM_ACTIVE_CHAIN"

echo ""
echo "INFO: override these values by updating $BCM_GIT_DIR/env"