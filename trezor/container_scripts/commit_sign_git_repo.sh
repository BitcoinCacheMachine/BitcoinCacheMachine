#!/bin/bash

# this file runs in the docker container.

git config --global commit.gpgsign 1
echo "git config --global commit.gpgsign:  $(git config --global --get commit.gpgsign)"

git config --global gpg.program $(which gpg2)
echo "git config --global gpg.program: $(git config --global --get gpg.program)"

git config --global user.name $BCM_GIT_CLIENT_USERNAME
echo "git config --global user.name set to '$(git config --global --get user.name)'"

# email must be passed in since a certificate can have many emails (uids)
git config --global user.email "$BCM_EMAIL_ADDRESS"
echo "git config --global user.email set to '$(git config --global --get user.email)'"

echo "Staging all outstanding changes."
git add *

echo "Committing and signing. Get ready to check your Trezor."
echo "BCM_GIT_COMMIT_MESSAGE: '$BCM_GIT_COMMIT_MESSAGE'"
git commit -a -m "$BCM_GIT_COMMIT_MESSAGE" --gpg-sign
