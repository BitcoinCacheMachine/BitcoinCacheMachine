

REMOTE_HOST_SSH_PRIVATE_KEY_PATH="$HOME/.ssh/bcm1.pem"
HOST_NAME=ec2-54-167-75-147.compute-1.amazonaws.com
USER_NAME=ubuntu

# generate a new SSH key for the remote hostname.
bcm ssh newkey --hostname="$HOST_NAME" --username="$USER_NAME"

# push that key to the remote host using the e
bcm ssh push --hostname="$HOST_NAME" --username="$USER_NAME" --ssh-key-path="$REMOTE_HOST_SSH_PRIVATE_KEY_PATH"


bcm ssh prepare --hostname="$HOST_NAME" --username="$USER_NAME"

# SSH connect to the remote host using Trezor for back end authentication
bcm ssh connect --hostname="$HOST_NAME" --username="$USER_NAME"


