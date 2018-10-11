#!/bin/bash


set -eu

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# these are the parameters
LXC_STACK="private_registry"
CERT_CN="privreg"
LXC_REMOTE=$(lxc remote get-default)
LXC_HOST=$BCM_LXC_GATEWAY_CONTAINER_NAME

DIR=~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK

# Let's generate some HTTPS certificate for the registry mirror
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/generate_and_sign_client_certificate.sh $LXC_HOST $LXC_STACK $CERT_CN"

if [[ -d $DIR ]]; then
    echo "Deploying $LXC_STACK to LXC host $LXC_HOST on LXD endpoint $LXC_REMOTE."

    lxc file push ./$LXC_STACK/ $LXC_HOST/apps/ -p -r
    lxc file push $DIR/$CERT_CN.cert $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/$CERT_CN.cert
    lxc file push  $DIR/$CERT_CN.key $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/$CERT_CN.key

    lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- docker stack deploy -c /apps/$LXC_STACK/private_registry.yml $CERT_CN
fi


    #lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- mkdir -p /apps/$LXC_STACK
    #lxc file push config.yml $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/config.yml
    #lxc file push $LXC_STACK.yml $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/$LXC_STACK/$LXC_STACK.yml
