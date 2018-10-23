#!/usr/bin/env bash

# this script generates a client certificate that is signed by the 
# BCM trusted root CA. The cert files are stored at ~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK/*

set -eu

# set current dir
cd "$(dirname "$0")"

LXC_REMOTE=$(lxc remote get-default)
LXC_HOST=$1
LXC_STACK=$2
CERT_CN=$3

DIR=~/.bcm/runtime/$LXC_REMOTE/$LXC_HOST/$LXC_STACK

if [[ ! -d $DIR ]]; then
    mkdir -p $DIR
    
    # create a client private key - remote client must have this to authenticate to the registry mirror
    openssl genrsa -out $DIR/$CERT_CN.key 4096

    # create a certificate signing request
    openssl req -new -key $DIR/$CERT_CN.key -out $DIR/$CERT_CN.csr -subj "/C=US/ST=BCM/L=INTERNET/O=BCM/CN=$CERT_CN"
    
    # now let's sign the CSR with the root CA
    openssl x509 -req -in $DIR/$CERT_CN.csr -CA ~/.bcm/certs/rootca.cert -CAkey  ~/.bcm/certs/rootca.key -CAcreateserial -out $DIR/$CERT_CN.cert -days 2048 -sha256

    openssl x509 -in $DIR/$CERT_CN.cert -outform DER -out $DIR/$CERT_CN.der
    
    cd ~/.bcm
    git add *
    git commit -am "Added $LXC_HOST certificate and secret key files to the admin machine at $DIR/$CERT_CN.cert"
    cd -
fi
