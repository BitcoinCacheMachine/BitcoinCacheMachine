#!/bin/bash

set -eu

cd "$(dirname "$0")"

LXC_REMOTE=$(lxc remote get-default)
LXC_HOST=$BCM_LXC_GATEWAY_CONTAINER_NAME
LXC_STACK=$1
CERT_CN=$2
TCP_PORT=$3
echo "################################"
echo "Running ./stack_deploy_template.sh with Stack of '$LXC_STACK', a CERT_CN of '$CERT_CN', and waiting for TCP PORT '$TCP_PORT'."

# Let's generate some HTTPS certificate for the lxc host stack
bash -c "$BCM_LOCAL_GIT_REPO_DIR/lxd/shared/generate_and_sign_client_certificate.sh $LXC_HOST $LXC_STACK $CERT_CN"

DIR=$BCM_RUNTIME_DIR/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK

if [[ -d $DIR ]]; then
    echo "Deploying $LXC_STACK to LXC host $LXC_HOST on LXD endpoint $LXC_REMOTE."

    # recursively push the contents of 'stack/stack_files/' to /apps on container;
    lxc file push ./$LXC_STACK/stack_files/* $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK -r -p

    lxc file push $DIR/$CERT_CN.cert $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/$CERT_CN.cert
    lxc file push $BCM_RUNTIME_DIR/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/$CERT_CN.key $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/$CERT_CN.key
    lxc file push $BCM_RUNTIME_DIR/certs/rootca.cert $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/ca.crt
fi

echo "outside ################"
lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker stack deploy -c /apps/$LXC_STACK/$LXC_STACK.yml $CERT_CN || true
lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- wait-for-it -t 0 "192.168.4.1:$TCP_PORT" || true