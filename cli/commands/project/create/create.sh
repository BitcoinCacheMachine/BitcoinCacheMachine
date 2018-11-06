#!/bin/bash

set -eu
cd "$(dirname "$0")"


BCM_HELP_FLAG=0
BCM_CLI_VERB=
BCM_PROJECT_NAME=
BCM_SHOW_ENDPOINTS_FLAG=0

for i in "$@"
do
case $i in
    --project-name=*)
    BCM_PROJECT_NAME="${i#*=}"
    shift # past argument=value
    ;;

    *)
    ;;
esac
done


if [[ -z $BCM_PROJECT_NAME ]]; then
    echo "Error: BCM_PROJECT_NAME is required."
    printhelp
    exit
fi


BCM_PROJECT_NAME=$BCM_PROJECT_NAME
BCM_PROJECT_BASE_DIR="$BCM_RUNTIME_DIR/projects"
BCM_PROJECT_DIR=$BCM_PROJECT_BASE_DIR/$BCM_PROJECT_NAME

# if the directory already exists we're going to quit
if [[ -d $BCM_PROJECT_DIR ]]; then
    echo "BCM project directory already exists. If you want to remove it, run 'bcm project destroy $BCM_PROJECT_NAME'"
    exit
fi

echo "BCM_PROJECT_NAME: '$BCM_PROJECT_NAME'"
echo "BCM_PROJECT_DIR: '$BCM_PROJECT_DIR'"

# if $BCM_PROJECT_BASE_DIR doesn't exist, create it.
if [ ! -d $BCM_PROJECT_BASE_DIR ]; then
    echo "Creating lxd_projects directory at $BCM_PROJECT_BASE_DIR"
    mkdir -p $BCM_PROJECT_BASE_DIR
fi

# if $BCM_RUNTIME_DIR/projects doesn't exist, create it.
if [ ! -d $BCM_PROJECT_DIR ]; then
    echo "Creating bcm project directory at $BCM_PROJECT_DIR"
    mkdir -p $BCM_PROJECT_DIR
fi

if [[ -z $BCM_PROJECT_USERNAME ]]; then
    echo "Error: BCM_PROJECT_USERNAME is required."
    printhelp
    exit
fi

if [[ -z $BCM_CLUSTER_NAME ]]; then
    echo "Error: BCM_CLUSTER_NAME is required."
    printhelp
    exit
fi

echo "BCM_PROJECT_USERNAME: '$BCM_PROJECT_USERNAME'"
echo "BCM_CLUSTER_NAME: '$BCM_CLUSTER_NAME'"

export BCM_PROJECT_NAME=$BCM_PROJECT_NAME
export BCM_PROJECT_DIR=$BCM_PROJECT_DIR
export BCM_PROJECT_USERNAME=$BCM_PROJECT_USERNAME
export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME
export BCM_TREZOR_USB_PATH=$BCM_TREZOR_USB_PATH

bash -c "$BCM_LOCAL_GIT_REPO_DIR/mgmt_plane/gpg-init.sh --cert-dir='$BCM_PROJECT_DIR' --cert-name='$BCM_PROJECT_NAME' --cert-username='$BCM_PROJECT_USERNAME' --cert-hostname='$BCM_CLUSTER_NAME'"

# let's just do a quick spot check to ensure the directory exists.
if [[ -d $BCM_PROJECT_DIR/trezor ]]; then
    bash -c "bcm project set-default $BCM_PROJECT_NAME"
fi

if [[ $BCM_HELP_FLAG = 1 ]]; then
    cat ./help.txt
fi