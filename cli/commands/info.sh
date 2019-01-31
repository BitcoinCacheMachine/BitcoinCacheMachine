#!/bin/bash

set -Eeuo pipefail

echo "TARGET_VARIABLES"

if [ -z ${BCM_CLUSTER_NAME+x} ]; then
    echo "  BCM_CLUSTER_NAME:           N/A";
else
    echo "  BCM_CLUSTER_NAME:           $BCM_CLUSTER_NAME";
fi

if [ -z ${BCM_CERT_NAME+x} ]; then
    echo "  BCM_CERT_NAME:              N/A";
else
    echo "  BCM_CERT_NAME:              $BCM_CERT_NAME";
fi

if [ -z ${BCM_CERT_USERNAME+x} ]; then
    echo "  BCM_CERT_USERNAME:          N/A";
else
    echo "  BCM_CERT_USERNAME:          $BCM_CERT_USERNAME";
fi

if [ -z ${BCM_CERT_HOSTNAME+x} ]; then
    echo "  BCM_CERT_HOSTNAME:          N/A";
else
    echo "  BCM_CERT_HOSTNAME:          $BCM_CERT_HOSTNAME";
fi

if [ -z ${BCM_PROJECT_NAME+x} ]; then
    echo "  BCM_PROJECT_NAME:           N/A";
else
    echo "  BCM_PROJECT_NAME:           $BCM_PROJECT_NAME";
fi


if [ -z ${BCM_SSH_HOSTNAME+x} ]; then
    echo "  BCM_SSH_HOSTNAME:           N/A";
else
    echo "  BCM_SSH_HOSTNAME:           $BCM_SSH_HOSTNAME";
fi

echo ""

echo "ACTIVE_ENVIRONMENT"
if [[ -d $GNUPGHOME ]]; then
    echo "  GNUPGHOME:                  $GNUPGHOME"
else
    echo "  GNUPGHOME:                  N/A"
fi

if [[ -d $PASSWORD_STORE_DIR ]]; then
    echo "  PASSWORD_STORE_DIR:         $PASSWORD_STORE_DIR"
else
    echo "  PASSWORD_STORE_DIR:         N/A"
fi

echo "  BCM_ACTIVE:                 $BCM_ACTIVE"
echo "  BCM_DEBUG:                  $BCM_DEBUG"

if [ -z ${BCM_CACHESTACK+x} ]; then
    echo "  BCM_CACHESTACK:             Not set.";
else
    echo "  BCM_CACHESTACK:             $BCM_CACHESTACK";
fi


# remove any legacy lxd software and install install lxd via snap
if snap list | grep -q lxd; then
    echo "  LXD_CLUSTER:                $(lxc remote get-default)"
    echo "  LXD_SERVER:                 $(lxc info | grep "server_name:" | awk 'NF>1{print $NF}')"
else
    echo ""
    echo "WARNING: LXD not installed locally."
fi