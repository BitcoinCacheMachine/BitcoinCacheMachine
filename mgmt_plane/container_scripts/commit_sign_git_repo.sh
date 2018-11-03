#!/bin/bash

set -eu

# set our working directory to the /gitrepo is which where out git repository
# should be mounted. This is what we're committing.
cd /gitrepo

export GNUPGHOME=/root/.gnupg/trezor

echo "GNUPGHOME: '$GNUPGHOME'"
echo "BCM_GIT_CLIENT_USERNAME: '$BCM_GIT_CLIENT_USERNAME'"
echo "BCM_EMAIL_ADDRESS: '$BCM_EMAIL_ADDRESS'"
echo "BCM_GIT_COMMIT_MESSAGE: '$BCM_GIT_COMMIT_MESSAGE'"
echo "BCM_GPG_SIGNING_KEY_ID: '$BCM_GPG_SIGNING_KEY_ID'"

git config --global commit.gpgsign 1
git config --global gpg.program $(which gpg2)
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
git add *

echo "Committing and signing. Get ready to check your Trezor."
git commit -S -m "$BCM_GIT_COMMIT_MESSAGE"
