#!/bin/bash

set -eu
cd "$(dirname "$0")"

# BCM_CLI_VERB=$2
BCM_TREZOR_SSH_USERNAME=
BCM_TREZOR_SSH_HOSTNAME=
BCM_CERT_DIR=
BCM_SSH_KEY_DIR=

for i in "$@"
do
case $i in
    --ssh-username=*)
    BCM_TREZOR_SSH_USERNAME="${i#*=}"
    shift # past argument=value
    ;;
    --ssh-hostname=*)
    BCM_TREZOR_SSH_HOSTNAME="${i#*=}"
    shift # past argument=value
    ;;
    --cert-dir=*)
    BCM_CERT_DIR="${i#*=}"
    shift # past argument=value
    ;;
    --ssh-key-dir=*)
    BCM_SSH_KEY_DIR="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done

export BCM_TREZOR_SSH_USERNAME=$BCM_TREZOR_SSH_USERNAME
export BCM_TREZOR_SSH_HOSTNAME=$BCM_TREZOR_SSH_HOSTNAME
export BCM_CERT_DIR=$BCM_CERT_DIR
export BCM_SSH_KEY_DIR=$BCM_SSH_KEY_DIR

if [[ $BCM_CLI_VERB = "newkey" ]]; then
    ./newkey/newkey.sh
elif [[ $BCM_CLI_VERB = "connect" ]]; then
    ./connect/connect.sh
else
    echo "Error, BCM_TREZOR_SSH_COMMAND invalid. Current value is '$BCM_TREZOR_SSH_COMMAND'"
fi