#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

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
mkdir -p "$TEMP_DIR"

./stub_env.sh --endpoint-name="$BCM_ENDPOINT_NAME" --master --ssh-username="$BCM_SSH_USERNAME" --ssh-hostname="$BCM_SSH_HOSTNAME"

# generate Trezor-backed SSH keys for interactively login.
#SSH_IDENTITY="$BCM_SSH_USERNAME"'@'"$BCM_SSH_HOSTNAME"
bcm ssh newkey --endpoint-name="$BCM_ENDPOINT_NAME" --cluster-name="$BCM_CLUSTER_NAME" --push

# since it's the master, let's grab the certificate so we can use it in subsequent lxd_preseed files.
LXD_CERT_FILE="$TEMP_DIR/$BCM_ENDPOINT_NAME/lxd.cert"

# makre sure we're on the correct LXC remote
if [[ $(lxc remote get-default) == "$BCM_CLUSTER_NAME" ]]; then
    # get the cluster master certificate using LXC.
    touch "$LXD_CERT_FILE"
    lxc info | awk '/    -----BEGIN CERTIFICATE-----/{p=1}p' | sed '1,/    -----END CERTIFICATE-----/!d' | sed "s/^[ \\t]*//" >>"$LXD_CERT_FILE"
fi

# let's mount the directory via sshfs. This contains the lxd seed file.
SSH_KEY_FILE="$TEMP_DIR/$BCM_ENDPOINT_NAME/id_rsa"
#LXD_TOR_HOSTNAME_FILE="$TEMP_DIR/$BCM_ENDPOINT_NAME/lxd_tor_hostname"
LXD_PRESEED_FILE="$TEMP_DIR/$BCM_ENDPOINT_NAME/lxd_preseed.yml"

# provision the machine by uploading the preseed and running the install script.
if [[ $BCM_SSH_HOSTNAME == *.onion ]]; then
    torify ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" mkdir -p "$REMOTE_MOUNTPOINT"
    torify scp -i "$SSH_KEY_FILE" "$LXD_PRESEED_FILE" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/lxd_preseed.yml"
    torify scp -i "$SSH_KEY_FILE" "$BCM_GIT_DIR/cli/commands/install/endpoint_provision.sh" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/endpoint_provision.sh"
    torify ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" chmod 0755 "$REMOTE_MOUNTPOINT/endpoint_provision.sh"
    torify ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" sudo bash -c "env BCM_TEMP_DIR=$BCM_TEMP_DIR $REMOTE_MOUNTPOINT/endpoint_provision.sh"
    torify wait-for-it -t -30 "$BCM_SSH_HOSTNAME:8443"
else
    ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" mkdir -p "$REMOTE_MOUNTPOINT"
    scp -i "$SSH_KEY_FILE" "$LXD_PRESEED_FILE" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/lxd_preseed.yml"
    scp -i "$SSH_KEY_FILE" "$BCM_GIT_DIR/cli/commands/install/endpoint_provision.sh" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/endpoint_provision.sh"
    ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" chmod 0755 "$REMOTE_MOUNTPOINT/endpoint_provision.sh"
    ssh -i "$SSH_KEY_FILE" -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" sudo bash -c "$REMOTE_MOUNTPOINT/endpoint_provision.sh"
    wait-for-it -t -30 "$BCM_SSH_HOSTNAME:8443"
fi


# if it's the cluster master add the LXC remote so we can manage it.
if ! lxc remote list --format csv | grep -q "$BCM_CLUSTER_NAME"; then
    source "$ENV_FILE"
    
    echo "Waiting for the remote lxd daemon to become available at $BCM_SSH_HOSTNAME."
    wait-for-it -t 0 "$BCM_SSH_HOSTNAME:8443"
    
    echo "Adding a lxd remote for cluster '$BCM_CLUSTER_NAME' at '$BCM_SSH_HOSTNAME:8443'."
    lxc remote add "$BCM_CLUSTER_NAME" "$BCM_SSH_HOSTNAME:8443" --accept-certificate --password="$BCM_LXD_SECRET"
    lxc remote switch "$BCM_CLUSTER_NAME"
fi

echo "Your new BCM cluster has been created. Your local LXD client is currently configured to target your new cluster."
echo "Consider adding hosts to your new cluster with 'bcm cluster add'. This helps achieve local high-availability."
