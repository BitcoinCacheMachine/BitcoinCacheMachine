


#!/bin/bash

# BCM_USER_NAME and BCM_HOST_NAME represent an identity on your trezor at a specific BIP32 path
# trezor produces a DETERMINISTIC "BCM_USER_NAME@BCM_HOST_NAME" keypair given a specific passphrase.
# it's RECOMMENDED that you use a SEPARATE passphrase for each trust level you determine: Could be
# along the lines of institutional trust, and deployment stages, e.g., dev, stage, prod.
#export BCM_HOST_NAME="ec2-54-86-51-14.compute-1.amazonaws.com"
#export BCM_USER_NAME=ubuntu
CLOUD_SSH_PRIVKEY="$HOME/.ssh/bcm1.pem"

# commit, stage, push to github (still over https.. TODO switch to trezor-backed SSH over Tor.)
bcm git commit --stage --message="Improved remote cluster deployment via 'bcm ssh prepare'." --push

# SSH connect to the remote host using Trezor for back end authentication
bcm ssh provision --hostname="$BCM_HOST_NAME" --username="$BCM_USER_NAME" --ssh-key-path="$CLOUD_SSH_PRIVKEY"


# # SSH connect to the remote host using Trezor for back end authentication
# bcm ssh connect --hostname="$HOST_NAME" --username="$USER_NAME"

# # now let's provision the cluster on the remote SSH endpoint. This command
# # deploys a bcm cluster to the current host/environment.
# bcm cluster create