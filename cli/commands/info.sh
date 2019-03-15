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
    if [[ "$(lxc remote get-default)" != "local" ]]; then
        echo "BCM_LXD_REMOTE:             $(lxc remote get-default)"
    else
        echo "BCM_LXD_REMOTE:             Not set."
    fi
else
    echo ""
    echo "WARNING: LXD not installed locally."
fi


if [ -z ${BCM_LXD_IMAGE_CACHE+x} ]; then
    echo "BCM_LXD_IMAGE_CACHE:        $BCM_LXD_IMAGE_CACHE";
else
    echo "BCM_LXD_IMAGE_CACHE:        images"
fi

if [ -z ${BCM_LXD_IMAGE_CACHE+x} ]; then
    echo "BCM_DOCKER_IMAGE_CACHE:     $BCM_DOCKER_IMAGE_CACHE";
else
    echo "BCM_LXD_IMAGE_CACHE:        https://registry-1.docker.io"
fi

if [ ! -z ${BCM_DEFAULT_CHAIN+x} ]; then
    echo "BCM_DEFAULT_CHAIN:          $BCM_DEFAULT_CHAIN";
fi
