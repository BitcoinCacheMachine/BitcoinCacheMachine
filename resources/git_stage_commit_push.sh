#!/bin/bash

source ./env

# first, let's commit and push our changes, so that the new VM will
# pull git from the published location. Note we do NOT mount BCM_GIT_DIR
# from the controller; it's always pulled from the GIT server endpoint
git add *

# LOCAL_GIT_NAME="$(git config --get --local user.name)"
# LOCAL_GIT_EMAIL="$(git config --get --local user.email)"

# DEFAULT_KEY_ID=$(gpg --no-permission-warning -k $LOCAL_GIT_EMAIL --keyid-format LONG | grep nistp256 | grep pub | sed 's/^[^/]*:/:/')
# DEFAULT_KEY_ID="${DEFAULT_KEY_ID#*/}"
# DEFAULT_KEY_ID="$(echo "$DEFAULT_KEY_ID" | awk '{print $1}')"

# export DEFAULT_KEY_ID="$DEFAULT_KEY_ID"


git commit -a -S --message="automated commit push."
git push
