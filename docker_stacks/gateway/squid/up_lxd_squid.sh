#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"
LXC_REMOTE=$(lxc remote get-default)

if [ ! -f ~/.bcm/runtime/$LXC_REMOTE/bcm-gateway/bcm.tld.cert ]; then
    echo "Generating a new CA Certificate for the squid forward proxy. Hosts depending on 'bcm-gateway' forward proxy MUST explicitly trust this CA."
    mkdir -p ~/.bcm/runtime/$LXC_REMOTE/bcm-gateway
    openssl req -new -newkey rsa:4096 -sha256 -days 365 -nodes -x509 -subj "/C=US/ST=BCM/L=INTERNET/O=BCM/CN=bcm.tld" -keyout ~/.bcm/runtime/$LXC_REMOTE/bcm-gateway/bcm.tld.key -out ~/.bcm/runtime/$LXC_REMOTE/bcm-gateway/bcm.tld.cert
    openssl x509 -in ~/.bcm/runtime/$LXC_REMOTE/bcm-gateway/bcm.tld.cert -outform DER -out ~/.bcm/runtime/$LXC_REMOTE/bcm-gateway/bcm.tld.cert.DER
    cd ~/.bcm
    git add *
    git commit -am "Added bcm-gateway SQUID CA certificate and secret key files to the admin machine at ~/.bcm/runtime/$LXC_REMOTE/"
    cd -
fi

echo "Deploying squid to 'bcm-gateway'."
lxc exec bcm-gateway -- mkdir -p /apps/squid

lxc file push squid.yml bcm-gateway/apps/squid/squid.yml
lxc file push squid.conf bcm-gateway/apps/squid/squid.conf

lxc exec bcm-gateway -- docker stack deploy -c /apps/squid/squid.yml squid
