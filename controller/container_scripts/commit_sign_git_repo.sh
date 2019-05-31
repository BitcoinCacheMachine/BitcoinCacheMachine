#!/bin/bash

set -e

# this script does a trezor-backed GPG signing operation on a git commit
# Note that the git repository mounted into /gitrepo MUST have some staged changes.

cd /gitrepo

echo "GNUPGHOME: '$GNUPGHOME'"
echo "GIT_CLIENT_USERNAME: '$GIT_CLIENT_USERNAME'"
echo "BCM_EMAIL_ADDRESS: '$BCM_EMAIL_ADDRESS'"
echo "GIT_COMMIT_MESSAGE: '$GIT_COMMIT_MESSAGE'"
echo "DEFAULT_KEY_ID: '$DEFAULT_KEY_ID'"

gpg2 --list-keys
git config --global commit.gpgsign 1
git config --global gpg.program "$(command -v gpg2)"
git config --global user.signingkey "$DEFAULT_KEY_ID"

echo "git config --global commit.gpgsign:  $(git config --global --get commit.gpgsign)"
echo "git config --global gpg.program: $(git config --global --get gpg.program)"
echo "git config --global user.signingkey: $(git config --global --get user.signingkey)"

git config --global user.name "$GIT_CLIENT_USERNAME"
echo "git config --global user.name set to '$(git config --global --get user.name)'"

# email must be passed in since a certificate can have many emails (uids)
git config --global user.email "$BCM_EMAIL_ADDRESS"
echo "git config --global user.email set to '$(git config --global --get user.email)'"

echo "Committing and signing. Get ready to check your Trezor."
git commit -S -m "$GIT_COMMIT_MESSAGE"

git log --show-signature -1