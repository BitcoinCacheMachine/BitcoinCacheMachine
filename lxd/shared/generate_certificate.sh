#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

LXC_REMOTE=$(lxc remote get-default)
LXC_HOST=$1
LXC_STACK=$2
CERT_CN=$3

if [ ! -f ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/$LXC_STACK.cert ]; then
    echo "Generating a new certificate on lxc host '$LXC_HOST' for stack '$LXC_STACK' using a CN of '$CERT_CN'."
    mkdir -p ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK
    openssl req -new -newkey rsa:4096 -sha256 -days 365 -nodes -x509 -subj "/C=US/ST=BCM/L=INTERNET/O=BCM/CN=$CERT_CN" -keyout ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/$LXC_STACK.key -out ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/$LXC_STACK.cert
    openssl x509 -in ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/$LXC_STACK.cert -outform DER -out ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/$LXC_STACK.cert.DER
    cd ~/.bcm
    git add *
    git commit -am "Added $LXC_HOST certificate and secret key files to the admin machine at ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/$LXC_STACK.cert"
    cd -
fi