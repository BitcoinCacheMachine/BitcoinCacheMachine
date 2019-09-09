


# generate a new SSH key for the remote hostname.
bcm ssh newkey --hostname="$HOST_NAME" --username="$USER_NAME"

# push that key to the remote host using the e
bcm ssh push --hostname="$HOST_NAME" --username="$USER_NAME" --ssh-key-path="$REMOTE_HOST_SSH_PRIVATE_KEY_PATH"



# now let's provision the cluster on the remote SSH endpoint.
bcm cluster create --driver="ssh" --ssh-hostname="$HOST_NAME" --ssh-username="$USER_NAME"

# SSH connect to the remote host using Trezor for back end authentication
bcm ssh provision --hostname="$HOST_NAME" --username="$USER_NAME"


# get a SSH TTY
# bcm ssh connect --hostname="$HOST_NAME" --username="$USER_NAME"


# commit, stage, push
# bcm git commit --stage --message="Message" --push