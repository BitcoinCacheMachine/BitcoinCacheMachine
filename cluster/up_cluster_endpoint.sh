#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

IS_MASTER=0
BCM_ENDPOINT_NAME=
BCM_ENDPOINT_VM_IP=

for i in "$@"; do
    case $i in
        --master)
            IS_MASTER=1
            shift # past argument=value
        ;;
        --cluster-name=*)
            BCM_CLUSTER_NAME="${i#*=}"
            shift # past argument=value
        ;;
        --endpoint-name=*)
            BCM_ENDPOINT_NAME="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

echo "IS_MASTER: $IS_MASTER"
echo "BCM_ENDPOINT_NAME: $BCM_ENDPOINT_NAME"
echo "BCM_SSH_HOSTNAME: $BCM_SSH_HOSTNAME"
echo "BCM_SSH_USERNAME: $BCM_SSH_USERNAME"

# let's mount the directory via sshfs. This contains the lxd seed file.
REMOTE_MOUNTPOINT="/tmp/bcm/provisioning"
SSH_KEY_FILE="$TEMP_DIR/$BCM_ENDPOINT_NAME/id_rsa"
#LXD_TOR_HOSTNAME_FILE="$TEMP_DIR/$BCM_ENDPOINT_NAME/lxd_tor_hostname"
LXD_PRESEED_FILE="$TEMP_DIR/$BCM_ENDPOINT_NAME/lxd_preseed.yml"

# provision the machine by uploading the preseed and running the install script.
if [[ $BCM_SSH_HOSTNAME == *.onion ]]; then
    torify ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" mkdir -p "$REMOTE_MOUNTPOINT"
    torify scp -i "$SSH_KEY_FILE" "$LXD_PRESEED_FILE" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/lxd_preseed.yml"
    torify scp -i "$SSH_KEY_FILE" "$BCM_GIT_DIR/cli/commands/install/endpoint_provision.sh" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/lxd_install.sh"
    torify ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" chmod 0755 "$REMOTE_MOUNTPOINT/lxd_install.sh"
    torify ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" -- sudo bash -c "env BCM_LXD_INIT=1 $REMOTE_MOUNTPOINT/lxd_install.sh"
    torify wait-for-it -t -30 "$BCM_SSH_HOSTNAME:8443"
else
    ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" mkdir -p "$REMOTE_MOUNTPOINT"
    scp -i "$SSH_KEY_FILE" "$LXD_PRESEED_FILE" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/lxd_preseed.yml"
    scp -i "$SSH_KEY_FILE" "$BCM_GIT_DIR/cli/commands/install/endpoint_provision.sh" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/lxd_install.sh"
    ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" chmod 0755 "$REMOTE_MOUNTPOINT/lxd_install.sh"
    ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" sudo bash -c "$REMOTE_MOUNTPOINT/lxd_install.sh"
    wait-for-it -t -30 "$BCM_SSH_HOSTNAME:8443"
    
    # ssh -i "$SSH_KEY_FILE" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" cat /tmp/lxd_tor_hostname > "$LXD_TOR_HOSTNAME_FILE"
    # ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" sudo rm /tmp/lxd_tor_hostname
    
    # cat "$LXD_TOR_HOSTNAME_FILE"
fi

# if it's the cluster master add the LXC remote so we can manage it.
if [[ $IS_MASTER == 1 ]]; then
    source "$ENV_FILE"
    
    echo "Waiting for the remote lxd daemon to become available at $BCM_ENDPOINT_VM_IP."
    wait-for-it -t 0 "$BCM_SSH_HOSTNAME:8443"
    
    echo "Adding a lxd remote for cluster '$BCM_CLUSTER_NAME' at '$BCM_SSH_HOSTNAME:8443'."
    lxc remote add "$BCM_CLUSTER_NAME" "$BCM_SSH_HOSTNAME:8443" --accept-certificate --password="$BCM_LXD_SECRET"
    
    echo "Setting BCM default LXD remote to '$BCM_CLUSTER_NAME'"
    lxc remote switch "$BCM_CLUSTER_NAME"
fi