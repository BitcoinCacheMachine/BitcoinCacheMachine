#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

ENDPOINT_DIR=
CLUSTER_NAME=$(lxc remote get-default)
BCM_SSH_USERNAME=
BCM_SSH_HOSTNAME=

# shellcheck disable=SC1091
source ./env

for i in "$@"; do
    case $i in
        --cluster-name=*)
            CLUSTER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --ssh-username=*)
            BCM_SSH_USERNAME="${i#*=}"
            shift # past argument=value
        ;;
        --ssh-hostname=*)
            BCM_SSH_HOSTNAME="${i#*=}"
            shift # past argument=value
        ;;
        --endpoint-dir=*)
            ENDPOINT_DIR="${i#*=}"
            shift
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z "$BCM_SSH_USERNAME" ]]; then
    echo "ERROR: BCM_SSH_USERNAME not specified. Use --ssh-username="
fi

if [[ -z "$BCM_SSH_HOSTNAME" ]]; then
    echo "ERROR: BCM_SSH_HOSTNAME not specified. Use --ssh-hostname="
fi

# if it's the cluster master add the LXC remote so we can manage it.
if lxc remote list --format csv | grep -q "$CLUSTER_NAME"; then
    echo "Switching lxd remote to local."
    lxc remote switch local
    
    echo "Removing lxd remote for cluster '$CLUSTER_NAME' at '$BCM_SSH_HOSTNAME:8443'."
    lxc remote remove "$CLUSTER_NAME"
fi

if [[ -d "$BCM_WORKING_DIR/$CLUSTER_NAME" ]]; then
    rm -rf "${BCM_WORKING_DIR:?}/$CLUSTER_NAME"
fi