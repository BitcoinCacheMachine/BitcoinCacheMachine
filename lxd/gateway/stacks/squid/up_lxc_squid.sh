#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# Let's generate some HTTPS certificates for the new registry mirror.
bash -c "../../../shared/generate_certificate.sh $BCM_LXC_GATEWAY_CONTAINER_NAME squid"

echo "Deploying squid to 'bcm-gateway'."
lxc exec bcm-gateway -- mkdir -p /apps/squid

lxc file push squid.yml bcm-gateway/apps/squid/squid.yml
lxc file push squid.conf bcm-gateway/apps/squid/squid.conf
lxc file push ~/.bcm/runtime/$(lxc remote get-default)/bcm-gateway/squid/squid.cert bcm-gateway/apps/squid/squid_ca.cert
lxc file push ~/.bcm/runtime/$(lxc remote get-default)/bcm-gateway/squid/squid.key bcm-gateway/apps/squid/squid.key
lxc exec bcm-gateway -- env docker stack deploy -c /apps/squid/squid.yml squid
