#!/bin/bash

set -Eeuo pipefail

BCM_CERT_NAME=
BCM_CERT_USERNAME=
BCM_CERT_HOSTNAME=
BCM_DEFAULT_KEY_ID=

echo "ACTIVE_ENVIRONMENT:"
if [ -z ${GNUPGHOME+x} ]; then
    echo "  --GNUPGHOME:           N/A";
else
    if [[ -d $GNUPGHOME ]]; then
        echo "  --GNUPGHOME:                  $GNUPGHOME"
        
        if [[ -f "$GNUPGHOME/env" ]]; then
            source "$GNUPGHOME/env"
            BCM_CERT_NAME="$BCM_CERT_NAME"
            BCM_CERT_USERNAME="$BCM_CERT_USERNAME"
            BCM_CERT_HOSTNAME="$BCM_CERT_HOSTNAME"
            BCM_DEFAULT_KEY_ID="$BCM_DEFAULT_KEY_ID"
            echo "    --CLUSTER_CERT_ID:              $BCM_DEFAULT_KEY_ID"
            echo "    --CLUSTER_CERT_TITLE:           $BCM_CERT_NAME <$BCM_CERT_USERNAME@$BCM_CERT_HOSTNAME>"
        fi
    else
        echo "  --GNUPGHOME:                  N/A"
    fi
fi

if [ -z ${PASSWORD_STORE_DIR+x} ]; then
    echo "  --PASSWORD_STORE_DIR:           N/A";
else
    if [[ -d $PASSWORD_STORE_DIR ]]; then
        echo "  --PASSWORD_STORE_DIR:         $PASSWORD_STORE_DIR"
    else
        echo "  --PASSWORD_STORE_DIR:         N/A"
    fi
fi

echo "  --BCM_ACTIVE:                 $BCM_ACTIVE"
echo "  --BCM_DEBUG:                  $BCM_DEBUG"

if [ -z ${BCM_CACHESTACK+x} ]; then
    echo "  --BCM_CACHESTACK:             Not set.";
else
    echo "  --BCM_CACHESTACK:             $BCM_CACHESTACK";
fi


# remove any legacy lxd software and install install lxd via snap
if snap list | grep -q lxd; then
    if [[ $(lxc remote get-default) != "local" ]]; then
        echo "  --LXD_CLUSTER:                $(lxc remote get-default)"
    else
        echo "  --LXD_CLUSTER:                Not set."
    fi
else
    echo ""
    echo "WARNING: LXD not installed locally."
fi

