#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

BCM_CERT_DIR=$BCM_RUNTIME_DIR/certs
BCM_CERT_NAME=
BCM_CERT_USERNAME=
BCM_CERT_FQDN=
BCM_CERT_DIR_OVERRIDE=


for i in "$@"
do
case $i in
    --cert-dir=*)
    BCM_CERT_DIR="${i#*=}"
    shift # past argument=value
    ;;
    --cert-name=*)
    BCM_CERT_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --cert-username=*)
    BCM_CERT_USERNAME="${i#*=}"
    shift # past argument=value
    ;;
    --cert-fqdn=*)
    BCM_CERT_FQDN="${i#*=}"
    shift # past argument=value
    ;;
    --cert-dir-override=*)
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


# if $BCM_RUNTIME_DIR doesn't exist, create it. THIS IS NOT A GIT REPO
if [ ! -d "$BCM_RUNTIME_DIR" ]; then
    echo "Creating Bitcoin Cache Machine git repo at $BCM_RUNTIME_DIR"
    mkdir -p "$BCM_RUNTIME_DIR"
    echo "Created $BCM_RUNTIME_DIR/ on $(date -u "+%Y-%m-%dT%H:%M:%S %Z")." > "$BCM_RUNTIME_DIR/debug.log"
fi

# if $BCM_RUNTIME_DIR doesn't exist, create it. THIS IS NOT A GIT REPO
if [ ! -d "$HOME/.password-store" ]; then
    echo "Creating $HOME/.password-store"
    mkdir -p "$HOME/.password-store"
fi

function createBCMGitRepo {
    # if $BCM_RUNTIME_DIR/certs doesn't exist, create it
    BCM_DIR=$1
    if [ ! -d "$BCM_DIR" ]; then
        echo "Creating Bitcoin Cache Machine repo at $BCM_DIR"
        mkdir -p "$BCM_DIR"
        git init "$BCM_DIR/"
        echo "Created $BCM_DIR/ on $(date -u "+%Y-%m-%dT%H:%M:%S %Z")." > "$BCM_DIR/debug.log"
    fi
}

# shellcheck disable=SC2153
createBCMGitRepo "$BCM_CERTS_DIR"
createBCMGitRepo "$BCM_PROJECTS_DIR"
createBCMGitRepo "$BCM_CLUSTERS_DIR"
createBCMGitRepo "$BCM_PASSWORDS_DIR"
createBCMGitRepo "$BCM_DEPLOYMENTS_DIR"

if [[ ! -z $BCM_CERT_DIR_OVERRIDE ]]; then
    BCM_CERT_DIR=$BCM_CERT_DIR_OVERRIDE
fi

# make sure docker is installed. Doing it here makes sure we don't have to do it anywhere else.
bash -c "$BCM_GIT_DIR/cli/commands/install/snap_install_docker-ce.sh"

bash -c "$BCM_GIT_DIR/controller/build.sh"

bash -c "$BCM_GIT_DIR/controller/gpg-init.sh \
    --cert-dir='$BCM_CERT_DIR' \
    --cert-name='$BCM_CERT_NAME' \
    --cert-username='$BCM_CERT_USERNAME' \
    --cert-hostname='$BCM_CERT_FQDN'"
