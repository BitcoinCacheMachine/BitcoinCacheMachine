#!/bin/bash

# this script pushes certificate client and key to a lxc host under its
# /apps/$LXC_STACK directory. It also pushes the root CA.

LXC_REMOTE=$(lxc remote get-default)
LXC_HOST=$1
LXC_STACK=$2
CERT_CN=$3

DIR=~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK

if [[ -d $DIR ]]; then
    echo "Pushing certificate files for '$CERT_CN' to LXC host '$LXC_HOST' on LXD endpoint '$LXC_REMOTE'."
    lxc exec $LXC_HOST -- mkdir -p /apps
    lxc file push $DIR/$CERT_CN.cert $LXC_HOST/apps/$LXC_STACK/$CERT_CN.cert
    lxc file push $DIR/$CERT_CN.key $LXC_HOST/apps/$LXC_STACK/$CERT_CN.key
    lxc file push ~/.bcm/certs/rootca.cert $LXC_HOST/apps/$LXC_STACK/ca.crt
fi