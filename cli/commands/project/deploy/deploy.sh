#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

BCM_PROJECT_NAME=
BCM_CLUSTER_NAME=

for i in "$@"; do
    case $i in
        --project-name=*)
            BCM_PROJECT_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --cluster-name=*)
            BCM_CLUSTER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if ! lxc remote list --format csv | grep -q "$BCM_CLUSTER_NAME"; then
    echo "BCM cluster '$BCM_CLUSTER_NAME' not found. Can't deploy project to it."
    exit
fi

if [[ -z "$BCM_PROJECT_NAME" ]]; then
    "$BCM_GIT_DIR/project/up.sh" --project-name="bcmbase" --cluster-name="$BCM_CLUSTER_NAME"
else
    "$BCM_GIT_DIR/project/up.sh" --project-name="$BCM_PROJECT_NAME" --cluster-name="$BCM_CLUSTER_NAME"
fi