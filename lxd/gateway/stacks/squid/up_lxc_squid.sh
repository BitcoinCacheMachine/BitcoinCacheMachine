#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

LXC_REMOTE=$(lxc remote get-default)
LXC_HOST=$BCM_LXC_GATEWAY_CONTAINER_NAME
LXC_STACK="squid"
CERT_CN="bcmnet"

# Let's generate some HTTPS certificate for the registry mirror
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/generate_and_sign_client_certificate.sh $BCM_LXC_GATEWAY_CONTAINER_NAME $LXC_STACK $CERT_CN"

bash -c "$BCM_LOCAL_GIT_REPO/docker_images/gateway/bcm-squid/build_lxd_bcm-squid.sh $BCM_LXC_GATEWAY_CONTAINER_NAME $BCM_DOCKER_BUILD_DOMAIN_IMAGE_PREFIX"

echo "Deploying squid to 'bcm-gateway'."
lxc exec bcm-gateway -- mkdir -p /apps/squid

lxc file push squid.yml bcm-gateway/apps/squid/squid.yml
lxc file push squid.conf bcm-gateway/apps/squid/squid.conf

lxc file push ~/.bcm/runtime/$LXC_REMOTE/bcm-gateway/registry_mirror/bcmnet.cert $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/squid/squid.cert
lxc file push ~/.bcm/runtime/$LXC_REMOTE/bcm-gateway/registry_mirror/bcmnet.key $BCM_LXC_GATEWAY_CONTAINER_NAME/apps/squid/squid.key

lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- chown root:root /apps/squid/squid.cert
lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- chown root:root /apps/squid/squid.key

lxc exec bcm-gateway -- docker stack deploy -c /apps/squid/squid.yml squid
