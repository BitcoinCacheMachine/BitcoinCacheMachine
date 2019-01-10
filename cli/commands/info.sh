#!/bin/bash

echo "TARGET_VARIABLES"
echo "  BCM_CLUSTER_NAME:       $BCM_CLUSTER_NAME"
echo "  BCM_CERT_NAME:          $BCM_CERT_NAME"
echo "  BCM_CERT_USERNAME:      $BCM_CERT_USERNAME"
echo "  BCM_CERT_HOSTNAME:      $BCM_CERT_HOSTNAME"
echo "  BCM_PROJECT_NAME:       $BCM_PROJECT_NAME"
echo "  BCM_PROJECT_USERNAME:   $BCM_PROJECT_USERNAME"
echo "  BCM_SSH_HOSTNAME: 	  $BCM_CLUSTER_SSH_ENDPOINT_NAME"
echo ""

echo "ACTIVE_ENVIRONMENT"
echo "  LXD_CLUSTER:            $(lxc remote get-default)"
echo "  LXD_SERVER:             $(lxc info | grep "server_name:" | awk 'NF>1{print $NF}')"

if [[ -d $GNUPGHOME ]]; then
	echo "  GNUPGHOME:              $GNUPGHOME"
else
	echo "  GNUPGHOME:          Error. Directory does not exist. You may need to run 'bcm init'"
fi

if [[ -d $PASSWORD_STORE_DIR ]]; then
	echo "  PASSWORD_STORE_DIR:     $PASSWORD_STORE_DIR"
else
	echo "  PASSWORD_STORE_DIR:     Error. Directory does not exist. You may need to run 'bcm init'"
fi

if [[ -d $SSH_DIR ]]; then
	echo "  SSH_DIR:                $SSH_DIR"
else
	echo "  SSH_DIR:                Error. Directory does not exist. You may need to run 'bcm init'"
fi

echo "  BCM_ACTIVE:             $BCM_ACTIVE"
echo "  BCM_DEBUG:              $BCM_DEBUG"
echo ""
