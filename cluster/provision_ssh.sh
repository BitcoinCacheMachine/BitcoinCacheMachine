#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

REMOTE_MOUNTPOINT="/home/$BCM_SSH_USERNAME/bcm"

# let's mount the directory via sshfs. This contains the lxd seed file.
ssh -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" mkdir -p $REMOTE_MOUNTPOINT
scp -r "$BCM_ENDPOINT_DIR/lxd_preseed.yml" "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME:$REMOTE_MOUNTPOINT/lxd_preseed.yml"

# run the snap_install script on the remote host.
ssh -t "$BCM_SSH_USERNAME@$BCM_SSH_HOSTNAME" "sudo eval $(cat $BCM_GIT_DIR/cli/commands/install/snap_lxd_install.sh)"
