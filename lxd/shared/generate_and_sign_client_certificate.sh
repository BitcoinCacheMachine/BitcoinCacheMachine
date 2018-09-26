#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

LXC_REMOTE=$(lxc remote get-default)
LXC_HOST=$1
LXC_STACK=$2
CERT_CN=$3

if [[ ! -d ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK ]]; then
    mkdir -p ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK
    
    # create a client private key - remote client must have this to authenticate to the registry mirror
    openssl genrsa -out ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/$CERT_CN.key 4096

    # create a certificate signing request
    openssl req -new -key ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/$CERT_CN.key -out ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/$CERT_CN.csr -subj "/C=US/ST=BCM/L=INTERNET/O=BCM/CN=$CERT_CN"

    # now let's sign the CSR with the root CA
    openssl x509 -req -in ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/$CERT_CN.csr \
    -CA  ~/.bcm/certs/rootca.cert  \
    -CAkey  ~/.bcm/certs/rootca.key -CAcreateserial \
    -out ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/$CERT_CN.cert -days 2048 -sha256

    cd ~/.bcm
    git add *
    git commit -am "Added $LXC_HOST certificate and secret key files to the admin machine at ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/$CERT_CN.cert"
    cd -
fi
