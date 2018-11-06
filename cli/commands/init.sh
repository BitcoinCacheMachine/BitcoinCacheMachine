#!/bin/bash

set -eu
cd "$(dirname "$0")"

echo "init "$@""
BCM_CERT_DIR=$BCM_RUNTIME_DIR/certs
BCM_CERT_NAME=
BCM_CERT_USERNAME=
BCM_CERT_FQDN=
BCM_CERT_DIR_OVERRIDE=

if [[ "$@" = "init" ]]; then
    BCM_HELP_FLAG=1
fi

for i in "$@"
do
case $i in
    -o=*|--cert-dir=*)
    BCM_CERT_DIR="${i#*=}"
    shift # past argument=value
    ;;
    -n=*|--cert-name=*)
    BCM_CERT_NAME="${i#*=}"
    shift # past argument=value
    ;;
    -u=*|--cert-username=*)
    BCM_CERT_USERNAME="${i#*=}"
    shift # past argument=value
    ;;
    -c=*|--cert-fqdn=*)
    BCM_CERT_FQDN="${i#*=}"
    shift # past argument=value
    ;;
    -o=*|--cert-dir-override=*)
    BCM_CERT_DIR_OVERRIDE="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done


if [[ $BCM_HELP_FLAG = 1 ]]; then
    cat ./init-help.txt
    exit
fi

if [[ -z $BCM_CERT_NAME  ]]; then
    echo "BCM_CERT_NAME not set."
    exit
fi


# if $BCM_RUNTIME_DIR doesn't exist, create it
if [ ! -d $BCM_RUNTIME_DIR ]; then
    echo "Creating Bitcoin Cache Machine git repo at $BCM_RUNTIME_DIR"
    mkdir -p $BCM_RUNTIME_DIR
    git init $BCM_RUNTIME_DIR/
    echo "Created $BCM_RUNTIME_DIR/ on $(date -u "+%Y-%m-%dT%H:%M:%S %Z")." > $BCM_RUNTIME_DIR/debug.log
fi

# if $BCM_RUNTIME_DIR/certs doesn't exist, create it
if [ ! -d $BCM_RUNTIME_DIR/certs ]; then
    echo "Creating Bitcoin Cache Machine certs repo at $BCM_RUNTIME_DIR/certs"
    mkdir -p $BCM_RUNTIME_DIR/certs
    git init $BCM_RUNTIME_DIR/certs/
    echo "Created $BCM_RUNTIME_DIR/certs/ on $(date -u "+%Y-%m-%dT%H:%M:%S %Z")." > $BCM_RUNTIME_DIR/debug.log
fi


if [[ ! -z $BCM_CERT_DIR_OVERRIDE ]]; then
    BCM_CERT_DIR=$BCM_CERT_DIR_OVERRIDE
fi

bash -c "$BCM_LOCAL_GIT_REPO_DIR/mgmt_plane/build.sh"

bash -c "$BCM_LOCAL_GIT_REPO_DIR/mgmt_plane/gpg-init.sh \
    --cert-dir='$BCM_CERT_DIR' \
    --cert-name='$BCM_CERT_NAME' \
    --cert-username='$BCM_CERT_USERNAME' \
    --cert-hostname='$BCM_CERT_FQDN'"
