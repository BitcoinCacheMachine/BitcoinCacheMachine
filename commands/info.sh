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

if [[ -d $PASSWORD_STORE_DIR ]]; then
    echo "  electrum_dir:              $ELECTRUM_DIR"
fi

if [[ -d $BCM_SSH_DIR ]]; then
    echo "  ssh_dir:                   $BCM_SSH_DIR"
fi

if [ ! -z ${BCM_DEBUG+x} ]; then
    echo "  cli_debug:                 $BCM_DEBUG"
fi

echo "  active_chain:              $BCM_ACTIVE_CHAIN"

echo "bcm_deployment:"

# remove any legacy lxd software and install install lxd via snap
echo "  active_cluster:            $BCM_CLUSTER_NAME"

CLUSTER_PROJECT="$(lxc project list | grep "(current)")"
CLUSTER_VERSION="$BCM_VERSION"
if ! echo "$CLUSTER_PROJECT" | grep -q "default"; then
    CLUSTER_VERSION=$(echo "$CLUSTER_PROJECT" | awk '{print $2}' | cut -d "_" -f 2)
fi
echo "  data_center:               $BCM_DATACENTER"
echo "  data_center_version:       $CLUSTER_VERSION"
