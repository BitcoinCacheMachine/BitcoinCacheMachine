#!/bin/bash

set -Eeuo pipefail

BCM_CERT_NAME=
BCM_CERT_USERNAME=
BCM_CERT_HOSTNAME=
BCM_DEFAULT_KEY_ID=

echo "ACTIVE_ENVIRONMENT:"
if [ -z ${GNUPGHOME+x} ]; then
    echo "GNUPGHOME:           N/A";
else
    if [[ -d $GNUPGHOME ]]; then
        echo "GNUPGHOME:                  $GNUPGHOME"
        
        if [[ -f "$GNUPGHOME/env" ]]; then
            # shellcheck disable=SC1090
            source "$GNUPGHOME/env"
            BCM_CERT_NAME="$BCM_CERT_NAME"
            BCM_CERT_USERNAME="$BCM_CERT_USERNAME"
            BCM_CERT_HOSTNAME="$BCM_CERT_HOSTNAME"
            BCM_DEFAULT_KEY_ID="$BCM_DEFAULT_KEY_ID"
            echo "  BCM_DEFAULT_KEY_ID:         $BCM_DEFAULT_KEY_ID"
            echo "  BCM_CERT_TITLE:             $BCM_CERT_NAME <$BCM_CERT_USERNAME@$BCM_CERT_HOSTNAME>"
        fi
    else
        echo "GNUPGHOME:                  N/A"
    fi
fi

if [ -z ${PASSWORD_STORE_DIR+x} ]; then
    echo "PASSWORD_STORE_DIR:           N/A";
else
    if [[ -d $PASSWORD_STORE_DIR ]]; then
        echo "PASSWORD_STORE_DIR:         $PASSWORD_STORE_DIR"
    else
        echo "PASSWORD_STORE_DIR:         N/A"
    fi
fi

if [ -z ${BCM_SSH_DIR+x} ]; then
    echo "BCM_SSH_DIR:           N/A";
else
    if [[ -d $BCM_SSH_DIR ]]; then
        echo "BCM_SSH_DIR:                $BCM_SSH_DIR"
    else
        echo "BCM_SSH_DIR:         N/A"
    fi
fi

echo "BCM_ACTIVE:                 $BCM_ACTIVE"
echo "BCM_DEBUG:                  $BCM_DEBUG"


# remove any legacy lxd software and install install lxd via snap
if snap list | grep -q lxd; then
    if [[ $(lxc remote get-default) != "local" ]]; then
        echo "LXD Remote:                 $(lxc remote get-default)"
    else
        echo "LXD Remote:                 Not set."
    fi
else
    echo ""
    echo "WARNING: LXD not installed locally."
fi


if [ -z ${LXD_IMAGE_CACHE+x} ]; then
    echo "LXD_IMAGE_CACHE:            Not set.";
else
    echo "LXD_IMAGE_CACHE:            $LXD_IMAGE_CACHE";
fi

if [ -z ${DOCKER_IMAGE_CACHE+x} ]; then
    echo "DOCKER_IMAGE_CACHE:         Not set.";
else
    echo "DOCKER_IMAGE_CACHE:         $DOCKER_IMAGE_CACHE";
fi

echo ""
echo "Local multipass VMs:"
multipass list