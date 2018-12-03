#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_PROJECT_NAME=
BCM_CLUSTER_NAME=
BCM_CLUSTER_DIR=

for i in "$@"
do
case $i in
    --project-name=*)
    BCM_PROJECT_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --cluster-name=*)
    BCM_CLUSTER_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --user-name=*)
    BCM_PROJECT_USERNAME="${i#*=}"
    shift # past argument=value
    ;;
    *)
          # unknown option
    ;;
esac
done


if [[ -z $(bcm project list | grep "$BCM_PROJECT_NAME") ]]; then
    echo "BCM project '$BCM_PROJECT_NAME' not found. Can't deploy."
    exit
fi

if [[ -z $(bcm cluster list | grep "$BCM_CLUSTER_NAME") ]]; then
    echo "BCM cluster '$BCM_CLUSTER_NAME' not found. Can't deploy project to it."
    exit

fi

BCM_DEPLOYMENT_DIR="$BCM_DEPLOYMENTS_DIR/$BCM_PROJECT_NAME"'_'"$BCM_CLUSTER_NAME"

if [[ ! -d $BCM_DEPLOYMENT_DIR ]]; then
    mkdir $BCM_DEPLOYMENT_DIR

    # first let's get some certificates generated for our new BCM deployment.
    $BCM_GIT_DIR/controller/gpg-init.sh \
        --cert-dir="$BCM_DEPLOYMENT_DIR" \
        --cert-name="$BCM_PROJECT_NAME" \
        --cert-username="$BCM_PROJECT_USERNAME" \
        --cert-hostname="$BCM_CLUSTER_NAME"
fi

BCM_PROJECT_NAME="$BCM_PROJECT_NAME"
BCM_CLUSTER_NAME="$BCM_CLUSTER_NAME"

bash -c "$BCM_GIT_DIR/project/up.sh --project-name=$BCM_PROJECT_NAME --cluster-name=$BCM_CLUSTER_NAME"