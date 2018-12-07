#!/bin/bash

set -Eeuo pipefail

cd /gitrepo

echo "DOCKER_GNUPGHOME: '$GNUPGHOME'"
echo "DOCKER_BCM_GIT_CLIENT_USERNAME: '$BCM_GIT_CLIENT_USERNAME'"
echo "DOCKER_BCM_EMAIL_ADDRESS: '$BCM_EMAIL_ADDRESS'"
echo "DOCKER_BCM_GIT_COMMIT_MESSAGE: '$BCM_GIT_COMMIT_MESSAGE'"
echo "DOCKER_BCM_GPG_SIGNING_KEY_ID: '$BCM_GPG_SIGNING_KEY_ID'"

git config --global commit.gpgsign 1
git config --global gpg.program "$(command -v gpg2)"
git config --global user.signingkey "$BCM_GPG_SIGNING_KEY_ID"

echo "git config --global commit.gpgsign:  $(git config --global --get commit.gpgsign)"
echo "git config --global gpg.program: $(git config --global --get gpg.program)"
echo "git config --global user.signingkey: $(git config --global --get user.signingkey)"

git config --global user.name "$BCM_GIT_CLIENT_USERNAME"
echo "git config --global user.name set to '$(git config --global --get user.name)'"

# email must be passed in since a certificate can have many emails (uids)
git config --global user.email "$BCM_EMAIL_ADDRESS"
echo "git config --global user.email set to '$(git config --global --get user.email)'"

echo "Staging all outstanding changes."
git add "*"

echo "Committing and signing. Get ready to check your Trezor."
git commit -S -m "$BCM_GIT_COMMIT_MESSAGE"
