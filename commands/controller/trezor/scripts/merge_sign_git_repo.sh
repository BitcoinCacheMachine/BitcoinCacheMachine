#!/bin/bash

set -e

echo "BCM_GIT_BRANCH: $BCM_GIT_BRANCH"
echo "DEFAULT_KEY_ID: '$DEFAULT_KEY_ID'"

gpg2 --list-keys

git config --local commit.gpgsign 1
git config --local gpg.program "$(command -v gpg2)"
git config --local user.signingkey "$DEFAULT_KEY_ID"

echo "git config --local commit.gpgsign:  $(git config --local --get commit.gpgsign)"
echo "git config --local gpg.program: $(git config --local --get gpg.program)"
echo "git config --local user.signingkey: $(git config --local --get user.signingkey)"
echo "git config --local user.name set to '$(git config --local --get user.name)'"

# email must be passed in since a certificate can have many emails (uids)
echo "git config --local user.email set to '$(git config --local --get user.email)'"

#signing with annotation and tag name, as required
echo "TaggingVerifying signatures and merging. Get ready to check your Trezor."
git merge --verify-signatures -S "$BCM_GIT_BRANCH"

git log --show-signature -1