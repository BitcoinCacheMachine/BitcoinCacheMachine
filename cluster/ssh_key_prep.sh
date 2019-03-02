#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

IS_MASTER=0
BCM_SSH_USERNAME=
BCM_SSH_HOSTNAME=
BCM_SSH_KEY_PATH=

for i in "$@"; do
    case $i in
        --master)
            IS_MASTER=1
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
        --ssh-key-path=*)
            BCM_SSH_KEY_PATH="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

if [[ -z "$BCM_SSH_USERNAME" ]]; then
    echo "ERROR: BCM_SSH_USERNAME not passed correctly."
    exit
fi

if [[ -z "$BCM_SSH_HOSTNAME" ]]; then
    echo "ERROR: BCM_SSH_HOSTNAME not passed correctly."
    exit
fi

ENDPOINT_DIR="$TEMP_DIR/$BCM_ENDPOINT_NAME"
mkdir -p "$ENDPOINT_DIR"
touch "$ENV_FILE"

bash -c "$BCM_GIT_DIR/cluster/ssh_key_prep.sh --ssh-key-path=$BCM_SSH_KEY_PATH --endpoint-dir=$ENDPOINT_DIR --ssh-username=$BCM_SSH_USERNAME  --ssh-hostname=$BCM_SSH_HOSTNAME"

# generate an LXD secret for the new VM lxd endpoint.
export BCM_ENDPOINT_NAME="$BCM_ENDPOINT_NAME"

BCM_LXD_SECRET="$(apg -n 1 -m 30 -M CN)"
export BCM_LXD_SECRET="$BCM_LXD_SECRET"
export BCM_SSH_USERNAME="$BCM_SSH_USERNAME"
export BCM_SSH_HOSTNAME="$BCM_SSH_HOSTNAME"

if [ $IS_MASTER -eq 1 ]; then
    envsubst <./envtemplates/master_defaults.env >"$ENV_FILE"
    elif [ $IS_MASTER -ne 1 ]; then
    envsubst <./envtemplates/member_defaults.env >"$ENV_FILE"
else
    echo "Incorrect usage. Please specify whether $BCM_ENDPOINT_NAME is an LXD cluster master or member."
fi

if [ $IS_MASTER -eq 1 ]; then
    envsubst <./lxd_preseed/lxd_master_preseed.yml >"$TEMP_DIR/$BCM_ENDPOINT_NAME/lxd_preseed.yml"
    #bcm pass insert --name="$BCM_CLUSTER_NAME/$BCM_ENDPOINT_NAME/lxd_preseed.yml"
    elif [ $IS_MASTER -ne 1 ]; then
    envsubst <./lxd_preseed/lxd_member_preseed.yml >"$TEMP_DIR/$BCM_ENDPOINT_NAME/lxd_preseed.yml"
else
    echo "Incorrect usage. Please specify whether $BCM_ENDPOINT_NAME is an LXD cluster master or member."
fi