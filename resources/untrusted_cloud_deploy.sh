


#!/bin/bash

HOST_NAME="ec2-54-86-51-14.compute-1.amazonaws.com"
USER_NAME=ubuntu
CLOUD_SSH_PRIVKEY="$HOME/.ssh/bcm1.pem"

# commit, stage, push to github (still over https.. TODO switch to trezor-backed SSH over Tor.)
bcm git commit --stage --message="Improved remote cluster deployment via 'bcm ssh prepare'." --push

# SSH connect to the remote host using Trezor for back end authentication
bcm ssh provision --hostname="$HOST_NAME" --username="$USER_NAME" --ssh-key-path="$CLOUD_SSH_PRIVKEY"


# # SSH connect to the remote host using Trezor for back end authentication
# bcm ssh connect --hostname="$HOST_NAME" --username="$USER_NAME"

# # now let's provision the cluster on the remote SSH endpoint. This command
# # deploys a bcm cluster to the current host/environment.
# bcm cluster create