#!/bin/bash

set -e

cd "$(dirname "$0")"

LXC_REMOTE=$(lxc remote get-default)
LXC_HOST=$BCM_LXC_GATEWAY_CONTAINER_NAME
LXC_STACK="squid"
CERT_CN="squid"

DIR=~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK

# Let's generate some HTTPS certificates for the new registry mirror.
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/generate_and_sign_client_certificate.sh $BCM_LXC_GATEWAY_CONTAINER_NAME $LXC_STACK $CERT_CN"

if [[ -d $DIR ]]; then
    echo "Deploying $LXC_STACK to LXC host $LXC_HOST on LXD endpoint $LXC_REMOTE."

    lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- mkdir -p /apps/$LXC_STACK

    lxc file push squid.yml $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/squid.yml
    lxc file push squid.conf $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/squid.conf

    lxc file push $DIR/$CERT_CN.cert $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/$CERT_CN.cert
    lxc file push $DIR/$CERT_CN.key $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/$CERT_CN.pem
    lxc file push ~/.bcm/certs/rootca.cert $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/ca.crt

    lxc exec bcm-gateway -- docker pull sameersbn/squid
    lxc exec bcm-gateway -- docker stack deploy -c /apps/squid/squid.yml squid
fi