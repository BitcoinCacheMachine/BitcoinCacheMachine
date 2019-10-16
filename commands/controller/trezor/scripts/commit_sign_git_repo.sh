#!/bin/bash

set -e

#sleep 180

echo "GIT_COMMIT_MESSAGE: '$GIT_COMMIT_MESSAGE'"
echo "DEFAULT_KEY_ID: '$DEFAULT_KEY_ID'"

gpg2 --list-keys
git config --local commit.gpgsign 1
git config --local gpg.program "$(command -v gpg2)"
git config --local user.signingkey "$DEFAULT_KEY_ID"

echo "git config --local commit.gpgsign:  $(git config --local --get commit.gpgsign)"
echo "git config --local gpg.program: $(git config --local --get gpg.program)"
echo "git config --local user.signingkey: $(git config --local --get user.signingkey)"
echo "git config --local user.name set to '$(git config --local --get user.name)'"
echo "git config --local user.email set to '$(git config --local --get user.email)'"

echo "Committing and signing. Get ready to check your Trezor."
git commit -S -m "$GIT_COMMIT_MESSAGE"

git log --show-signature -1
