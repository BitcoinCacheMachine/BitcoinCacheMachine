#!/bin/bash

set -eu

cd "$(dirname "$0")"

LXC_REMOTE=$(lxc remote get-default)
LXC_HOST=$BCM_LXC_GATEWAY_CONTAINER_NAME
LXC_STACK=$1
CERT_CN=$2
TCP_PORT=$3

DIR=~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK

# Let's generate some HTTPS certificate for the registry mirror
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/generate_and_sign_client_certificate.sh $LXC_HOST $LXC_STACK $CERT_CN"

if [[ -d $DIR ]]; then
    echo "Deploying $LXC_STACK to LXC host $LXC_HOST on LXD endpoint $LXC_REMOTE."

    lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- mkdir -p /apps/$LXC_STACK

    lxc file push ./$LXC_STACK/$LXC_STACK/ $LXC_HOST/apps/ -p -r

    lxc file push $DIR/$CERT_CN.cert $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/$CERT_CN.cert
    lxc file push ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/$CERT_CN.key $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/$CERT_CN.key
    lxc file push ~/.bcm/certs/rootca.cert $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/ca.crt

    lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker stack deploy -c /apps/$LXC_STACK/$LXC_STACK.yml $CERTCN


fi