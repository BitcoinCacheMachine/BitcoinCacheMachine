#!/bin/bash

set -Eeuo pipefail

BCM_CERT_NAME=
BCM_CERT_USERNAME=
BCM_CERT_HOSTNAME=
BCM_DEFAULT_KEY_ID=

# echo "TARGET_VARIABLES"

# if [ -z ${BCM_CLUSTER_NAME+x} ]; then
#     echo "  BCM_CLUSTER_NAME:           N/A";
# else
#     echo "  BCM_CLUSTER_NAME:           $BCM_CLUSTER_NAME";
# fi

# if [ -z ${BCM_SSH_USERNAME+x} ]; then
#     echo "  BCM_SSH_USERNAME:           N/A";
# else
#     echo "  BCM_SSH_USERNAME:           $BCM_SSH_USERNAME";
# fi

# if [ -z ${BCM_SSH_HOSTNAME+x} ]; then
#     echo "  BCM_SSH_HOSTNAME:           N/A";
# else
#     echo "  BCM_SSH_HOSTNAME:           $BCM_SSH_HOSTNAME";
# fi

# if [ -z ${BCM_PROJECT_NAME+x} ]; then
#     echo "  BCM_PROJECT_NAME:           N/A";
# else
#     echo "  BCM_PROJECT_NAME:           $BCM_PROJECT_NAME";
# fi

# echo ""

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
    echo "  --LXD_CLUSTER:                $(lxc remote get-default)"
else
    echo ""
    echo "WARNING: LXD not installed locally."
fi

