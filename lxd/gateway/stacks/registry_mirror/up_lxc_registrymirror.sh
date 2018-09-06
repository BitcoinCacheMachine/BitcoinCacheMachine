#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# Let's generate some HTTPS certificates for the new registry mirror.
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/generate_certificate.sh $BCM_LXC_GATEWAY_CONTAINER_NAME registry_mirror bcmnet:5000"


# let's generate a client certificate too
bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/generate_certificate.sh $BCM_LXC_GATEWAY_CONTAINER_NAME registry_mirror bcmnet"


# create a client certificate - remote client must have this to authenticate to the registry mirror
openssl genrsa -out ~/.bcm/runtime/$(lxc remote get-default)/bcmnet_template/client.key 4096
openssl req -new -x509 -text -subj "/C=US/ST=BCM/L=INTERNET/O=BCM/CN=client" -key ~/.bcm/runtime/$(lxc remote get-default)/bcmnet_template/client.key -out ~/.bcm/runtime/$(lxc remote get-default)/bcmnet_template/client.cert
lxc file push ~/.bcm/runtime/$(lxc remote get-default)/bcmnet_template/client.key $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME/etc/docker/certs.d/bcmnet:5000/client.key
lxc file push ~/.bcm/runtime/$(lxc remote get-default)/bcmnet_template/client.cert $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME/etc/docker/certs.d/bcmnet:5000/client.cert


echo "Deploying registry mirrors to the active LXD endpoint."
lxc exec bcm-gateway -- mkdir -p /apps/registry_mirror
lxc file push config.yml bcm-gateway/apps/registry_mirror/config.yml
lxc file push registry_mirror.yml bcm-gateway/apps/registry_mirror/registry_mirror.yml
lxc file push ~/.bcm/runtime/$(lxc remote get-default)/bcm-gateway/registry_mirror/registry_mirror.cert bcm-gateway/apps/registry_mirror/regmirror.cert
lxc file push ~/.bcm/runtime/$(lxc remote get-default)/bcm-gateway/registry_mirror/registry_mirror.key bcm-gateway/apps/registry_mirror/regmirror.key

lxc exec bcm-gateway -- docker stack deploy -c /apps/registry_mirror/registry_mirror.yml registrymirror
