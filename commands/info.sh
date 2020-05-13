#!/bin/bash

set -Eeuo pipefail

echo "BCM_TARGET_VERSION:        $BCM_VERSION"
echo "GNUPGHOME:                 $GNUPGHOME"
echo "DEFAULT_KEY_ID:            $DEFAULT_KEY_ID"

if [[ -d $PASSWDHOME ]]; then
    echo "PASSWDHOME:                $PASSWDHOME"
fi

echo "SSHHOME:                   $SSHHOME"
echo "BCM_VM_NAME:               $BCM_VM_NAME"
echo "BCM_MACVLAN_INTERFACE:     $BCM_MACVLAN_INTERFACE"
echo "BCM_CACHE_DIR:             $BCM_CACHE_DIR"
echo "BCM_DEBUG:                 $BCM_DEBUG"
echo "BCM_SSH_HOSTNAME:          $BCM_SSH_HOSTNAME"
echo "BCM_SSH_USERNAME:          $BCM_SSH_USERNAME"
echo "BCM_DATACENTER:            $BCM_DATACENTER"
echo "BCM_PROJECT:               $BCM_PROJECT"
echo "BCM_ACTIVE_CHAIN:          $BCM_ACTIVE_CHAIN"

echo ""
echo "INFO: override these values by updating $BCM_GIT_DIR/env"
