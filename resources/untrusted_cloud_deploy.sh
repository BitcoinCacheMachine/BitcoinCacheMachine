


#!/bin/bash

# SSH connect to the remote host using Trezor for back end authentication
bcm ssh provision --hostname="$HOST_NAME" --username="$USER_NAME" --ssh-key-path="$CLOUD_SSH_PRIVKEY"

# SSH connect to the remote host using Trezor for back end authentication
bcm ssh connect --hostname="$HOST_NAME" --username="$USER_NAME"

# now let's provision the cluster on the remote SSH endpoint.
bcm cluster create --driver="ssh" --ssh-hostname="$HOST_NAME" --ssh-username="$USER_NAME"

# commit, stage, push to github (still over https.. TODO switch to trezor-backed SSH over Tor.)
bcm git commit --stage --message="Improved remote cluster deployment via 'bcm ssh prepare'." --push
