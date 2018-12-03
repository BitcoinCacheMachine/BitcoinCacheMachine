#!/bin/bash

cd "$(dirname "$0")"
set -Eeuo pipefail

source "$BCM_GIT_DIR/.env"

BCM_CLUSTER_NAME=
BCM_DEBUG=0

for i in "$@"
do
case $i in
    --cluster-name=*)
    BCM_CLUSTER_NAME="${i#*=}"
    shift # past argument=value
    ;;
    --debug)
    BCM_DEBUG=1
    shift # past argument=value
    ;;
    *)

    ;;
esac
done

if [[ -z $BCM_CLUSTER_NAME ]]; then
  echo "BCM_CLUSTER_NAME not set. Exiting."
  exit
fi

if [[ ! -d "$BCM_CLUSTERS_DIR/$BCM_CLUSTER_NAME" ]]; then
  echo "BCM cluster definition '$BCM_CLUSTER_NAME' does not exist. Nothing to destroy."
  exit
fi

if [[ $BCM_DEBUG = 1 ]]; then
  echo "Running destroy_cluster.sh with the following parameters:"
  echo "BCM_CLUSTER_NAME: $BCM_CLUSTER_NAME"
  echo "BCM_CLUSTER_NAME: $BCM_CLUSTER_NAME"
fi

echo "Destroying BCM Cluster '$BCM_CLUSTER_NAME'"
export BCM_CLUSTER_DIR=$BCM_RUNTIME_DIR/clusters/$BCM_CLUSTER_NAME
export ENDPOINTS_DIR="$BCM_CLUSTER_DIR/endpoints"

if [[ $BCM_DEBUG = 1 ]]; then
  echo "BCM_CLUSTER_DIR: $BCM_CLUSTER_DIR"
  echo "ENDPOINTS_DIR: $ENDPOINTS_DIR"
fi

for endpoint in $(bcm cluster list --endpoints); do
  ./destroy_cluster_endpoint.sh --cluster-name=$BCM_CLUSTER_NAME --endpoint-name=$endpoint
done

if [[ $(lxc remote list | grep $BCM_CLUSTER_NAME) ]]; then
  lxc remote switch local
  lxc remote remove $BCM_CLUSTER_NAME
fi

if [[ -d "$BCM_CLUSTER_DIR" ]]; then
  rm -rf "$BCM_CLUSTER_DIR"
fi

# delete profile 'docker-privileged'
bash -c "$BCM_LXD_OPS/delete_lxc_profile.sh --profile-name=bcm_default"

# source $BCM_CERTS_DIR/.env
# bcm git commit \
#     --cert-dir="$BCM_CERTS_DIR" \
#     --git-repo-dir="$BCM_CLUSTERS_DIR" \
#     --git-commit-message="Destroyed cluster $BCM_CLUSTER_NAME and all associated files." \
#     --git-username="$BCM_CERT_USERNAME" \
#     --email-address="$BCM_CERT_USERNAME@$BCM_CERT_FQDN" \
#     --gpg-signing-key-id="$BCM_DEFAULT_KEY_ID"