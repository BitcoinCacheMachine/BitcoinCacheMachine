#!/bin/bash

set -eu
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
    $BCM_LOCAL_GIT_REPO_DIR/mgmt_plane/gpg-init.sh \
        --cert-dir="$BCM_DEPLOYMENT_DIR" \
        --cert-name="$BCM_PROJECT_NAME" \
        --cert-username="$BCM_PROJECT_USERNAME" \
        --cert-hostname="$BCM_CLUSTER_NAME"
fi

export BCM_PROJECT_NAME=$BCM_PROJECT_NAME
export BCM_CLUSTER_NAME=$BCM_CLUSTER_NAME
export BCM_CLUSTER_DIR=$BCM_CLUSTERS_DIR/$BCM_CLUSTER_NAME

$BCM_LOCAL_GIT_REPO_DIR/lxd/up_bcm_project.sh
