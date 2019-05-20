#!/bin/bash

set -Eeuo pipefail

BCM_CERT_NAME=
BCM_CERT_USERNAME=
BCM_CERT_HOSTNAME=
DEFAULT_KEY_ID=

echo "bcm_client:"
echo "  client_version:            $BCM_VERSION";

if [[ ! -z $BCM_RUNTIME_DIR && -d $BCM_RUNTIME_DIR ]]; then
    echo "  runtime_dir:               $BCM_RUNTIME_DIR";
fi

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

echo "  cli_debug:                 $BCM_DEBUG"
echo "  active_chain:              $BCM_ACTIVE_CHAIN";


echo "bcm_deployment:"

# remove any legacy lxd software and install install lxd via snap
if ! lxc remote get-default | grep -q "local"; then
    echo "  active_cluster:            $(lxc remote get-default)"
    
    CLUSTER_PROJECT="$(lxc project list | grep "(current)")"
    CLUSTER_VERSION="$BCM_VERSION"
    if ! echo "$CLUSTER_PROJECT" | grep -q "default"; then
        CLUSTER_VERSION=$(echo "$CLUSTER_PROJECT" | awk '{print $2}' | cut -d "_" -f 2)
    fi
    echo "  data_center:               $BCM_DATACENTER";
    echo "  cluster_version:           $CLUSTER_VERSION"
    
    # let's show some LXD cluster related stuff.
    if [ ! -z ${BCM_LXD_IMAGE_CACHE+x} ]; then
        echo "  lxd_image_cache:           $BCM_LXD_IMAGE_CACHE";
    fi
    
    if [ ! -z ${BCM_DOCKER_IMAGE_CACHE_FQDN+x} ]; then
        echo "  registry_mirror_host:      $BCM_DOCKER_IMAGE_CACHE_FQDN";
    fi
else
    echo "  active_cluster:            N/A"
fi
