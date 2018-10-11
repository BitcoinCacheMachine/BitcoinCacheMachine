#!/bin/bash

# goal of this script is to spin up a basic working LXC container that's
# ready to run docker containers and has 1 interface exclusively connecting
# to bcmnet.

set -e

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# Create the bcmnet_template template lxc container only it doesnt exist yet.
if [[ $(lxc list | grep $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME) ]]; then
    echo "LXC container '$BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME' exists."
    exit 1
fi

# call bcm_script_before.sh to perform the things that every BCM script must do prior to proceeding
bash -c $BCM_LOCAL_GIT_REPO/resources/bcm/bcm_script_before.sh

# if bcm-template lxc image exists, run the rest of the script.
if [[ -z $(lxc image list | grep "bcm-template") ]]; then
    echo "Required LXC image 'bcm-template' does not exist! Ensure your current LXD remote $(lxc remote get-default)."
    exit 1
fi

# create a bcmnet_template template if it doesn't exist.
if [[ -z $(lxc list | grep "$BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME") ]]; then
    # let's generate a LXC template to base our lxc container on.
    lxc init bcm-template $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME -p bcm_disk -p docker_privileged
fi

lxc file push 10-lxc.yaml $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME/etc/netplan/10-lxc.yaml

echo "Starting '$BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME'."
lxc start $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME

sleep 10

bash -c "$BCM_LOCAL_GIT_REPO/lxd/shared/wait_for_dockerd.sh $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME"

#we're going to update the docker daemon to use the HTTP/HTTPs proxy on gateway.
lxc exec $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME -- mkdir -p /etc/systemd/system/docker.service.d
lxc file push https-proxy.conf $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME/etc/systemd/system/docker.service.d/https-proxy.conf
lxc file push http-proxy.conf $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME/etc/systemd/system/docker.service.d/http-proxy.conf

# configure default environment to also use the squid proxy on gateway.
lxc config set $BCM_LXC_BCMNETTEMPLATE_CONTAINER_NAME environment.HTTP_PROXY http://squid:3128/
lxc config set $BCM_LXC_BCMNETTEMPLATE_CONTAINER_NAME environment.HTTPS_PROXY http://squid:3128/

# put the squid proxy certificate on the template.
lxc exec $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME -- mkdir -p /etc/squid/ssl_cert
lxc file push ~/.bcm/runtime/$(lxc remote get-default)/bcm-gateway/squid/squid.DER $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME/etc/squid/ssl_cert/myCA.pem

# let's disable the docker daemon because we have to start it a special way due to HTTPS proxy
lxc exec $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME -- systemctl disable docker

# update docker client to support HTTP/HTTPS
lxc exec $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME -- mkdir /root/.docker

lxc file push docker_client.config.json $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME/root/.docker/config.json

lxc stop $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME

# create a snapshot from which all production managers will be based.
lxc snapshot $BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME "bcmnet_template"

echo "Done creating '$BCM_LXC_BCMNETTEMPLATE_CONTAINER_TEMPLATE_NAME' LXC conatiner snapshot. Deploying bcmnet hosts."
