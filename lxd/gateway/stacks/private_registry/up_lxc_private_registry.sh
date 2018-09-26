#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# these are the parameters
LXC_STACK="private_registry"
CERT_CN="bcmnet"

LXC_REMOTE=$(lxc remote get-default)
LXC_HOST=$BCM_LXC_GATEWAY_CONTAINER_NAME

# Let's generate some HTTPS certificate for the registry mirror
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/generate_and_sign_client_certificate.sh $BCM_LXC_GATEWAY_CONTAINER_NAME $LXC_STACK $CERT_CN"

if [[ -d ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK ]]; then
    echo "Deploying $LXC_STACK to LXC host $LXC_HOST on LXD endpoint $LXC_REMOTE."

    lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- mkdir -p /apps/$LXC_STACK
    lxc file push config.yml $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/config.yml
    lxc file push $LXC_STACK.yml $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/$LXC_STACK.yml

    lxc file push ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/$CERT_CN.cert $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/$CERT_CN.cert
    lxc file push  ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/$CERT_CN.key $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/$CERT_CN.key

    lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- env REGISTRY_HTTP_SECRET="CHANGEME" docker stack deploy -c /apps/$LXC_STACK/$LXC_STACK.yml $LXC_STACK
fi