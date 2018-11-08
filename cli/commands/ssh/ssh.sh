#!/bin/bash

set -e

# example usage:  
# newkey: you get a unique keypair per BIP32PATH/u/h tuple.
# ./ssh.sh -c newkey -u BitcoinCacheMachine -h github.com
# ./ssh.sh -c connect -u BitcoinCacheMachine -h github.com


cd "$(dirname "$0")"

# this block provides with with a new SSH key generated from the Trezor
# params are -u for username and -h for host. e.g., bob@github.com
if [[ ! -z $(docker ps -a | grep bcmtrezorsshagent) ]]; then
    if [[ ! -z $(docker ps | grep bcmtrezorsshagent) ]]; then
        docker kill bcmtrezorsshagent
    fi

    docker system prune -f
fi

# let's the arguments passed in on the terminal
# member count is really the number of nodes BEYOND the first cluster member.
while getopts u:h:c: option
do
    case "${option}"
    in
    u) export BCM_TREZOR_SSH_USERNAME=${OPTARG};;
    h) export BCM_TREZOR_SSH_HOSTNAME=${OPTARG};;
    c) export BCM_TREZOR_SSH_COMMAND=${OPTARG};;
    s) export BCM_TREZOR_SSH_AUTHORIZED_KEYS_DIR=${OPTARG};;
    esac
done

if [[ -z $BCM_TREZOR_SSH_USERNAME ]]; then
    echo "BCM_TREZOR_SSH_USERNAME empty."
    exit
fi

if [[ -z $BCM_TREZOR_SSH_HOSTNAME ]]; then
    echo "BCM_TREZOR_SSH_HOSTNAME empty."
    exit
fi

if [[ -z $BCM_CERT_DIR ]]; then
    echo "BCM_CERT_DIR is empty. Setting to '$BCM_RUNTIME_DIR/projects/bcm-dev/trezor'"
    export BCM_CERT_DIR="$BCM_RUNTIME_DIR/projects/bcm-dev/trezor"
fi




echo "BCM_CERT_DIR: $BCM_CERT_DIR"


if [[ -z $BCM_TREZOR_SSH_AUTHORIZED_KEYS_DIR ]]; then
    echo "BCM_TREZOR_SSH_AUTHORIZED_KEYS_DIR is empty. Setting to $BCM_RUNTIME_DIR/projects/bcm-dev/mgmt_plane/ssh"
    export BCM_TREZOR_SSH_AUTHORIZED_KEYS_DIR=$BCM_RUNTIME_DIR/projects/bcm-dev/mgmt_plane/ssh
fi

echo "BCM_TREZOR_SSH_AUTHORIZED_KEYS_DIR: $BCM_TREZOR_SSH_AUTHORIZED_KEYS_DIR"

source $BCM_LOCAL_GIT_REPO_DIR/dev_machine/mgmt_plane/export_usb_path.sh



if [[ ! -z $TREZOR_USB_PATH ]]; then


    if [[ $BCM_TREZOR_SSH_COMMAND = "newkey" ]]; then
        bash -c ./newkey.sh
    elif [[ $BCM_TREZOR_SSH_COMMAND = "connect" ]]; then
        bash -c ./connect.sh
    else
        echo "Error, BCM_TREZOR_SSH_COMMAND invalid. Current value is '$BCM_TREZOR_SSH_COMMAND'"
    fi

    #docker kill bcmtrezorsshagent
    docker system prune -f
fi