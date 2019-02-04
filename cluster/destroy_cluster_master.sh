#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# shellcheck disable=1090
source "$BCM_GIT_DIR/env"

BCM_CLUSTER_NAME=
BCM_SSH_USERNAME=
BCM_SSH_HOSTNAME=

for i in "$@"; do
    case $i in
        --cluster-name=*)
            BCM_CLUSTER_NAME="${i#*=}"
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
        *)
            # unknown option
        ;;
    esac
done


if [[ -z "$BCM_SSH_USERNAME" ]]; then
    echo "ERROR: BCM_SSH_USERNAME not specified."
fi

if [[ -z "$BCM_SSH_HOSTNAME" ]]; then
    echo "ERROR: BCM_SSH_HOSTNAME not specified."
fi

source ./env

# if it's the cluster master add the LXC remote so we can manage it.
if lxc remote list --format csv | grep -q "$BCM_CLUSTER_NAME"; then
    echo "Switching lxd remote to local."
    lxc remote switch local
    
    echo "Removing lxd remote for cluster '$BCM_CLUSTER_NAME' at '$BCM_SSH_HOSTNAME:8443'."
    lxc remote remove "$BCM_CLUSTER_NAME"
fi

# let's mount the directory via sshfs. This contains the lxd seed file.
REMOTE_MOUNTPOINT="/tmp/bcm/provisioning"
SSH_KEY_FILE="$TEMP_DIR/$BCM_ENDPOINT_NAME/id_rsa"

# provision the machine by uploading the preseed and running the install script.
if [[ "$BCM_SSH_HOSTNAME" == *.onion ]]; then
    echo "TODO"
else
    if [[ -f "$SSH_KEY_FILE" ]]; then
        ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" mkdir -p "$REMOTE_MOUNTPOINT"
        scp -i "$SSH_KEY_FILE" "$BCM_GIT_DIR/cli/commands/install/endpoint_deprovision.sh" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/endpoint_deprovision.sh"
        ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" chmod 0755 "$REMOTE_MOUNTPOINT/endpoint_deprovision.sh"
        ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" sudo bash -c "$REMOTE_MOUNTPOINT/endpoint_deprovision.sh"
    else
        ssh -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" mkdir -p "$REMOTE_MOUNTPOINT"
        scp "$BCM_GIT_DIR/cli/commands/install/endpoint_deprovision.sh" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/endpoint_deprovision.sh"
        ssh -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" chmod 0755 "$REMOTE_MOUNTPOINT/endpoint_deprovision.sh"
        ssh -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" sudo bash -c "$REMOTE_MOUNTPOINT/endpoint_deprovision.sh"
    fi
fi
