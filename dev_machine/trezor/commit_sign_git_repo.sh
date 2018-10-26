#!/bin/bash

git config --global commit.gpgsign 1
echo "git config --global commit.gpgsign:  $(git config --global --get commit.gpgsign)"

git config --global gpg.program $(which gpg2)
echo "git config --global gpg.program: $(git config --global --get gpg.program)"

git config --global user.name "$BCM_GIT_CLIENT_USERNAME"
echo "git config --global user.name set to '$(git config --global --get user.name)'"

git config --global user.email "$BCM_PROJECT_CERTIFICATE_EMAIL"
echo "git config --global user.email set to '$(git config --global --get user.email)'"

#git config --global user.signingkey $BCM_GIT_SIGNING_KEY
#echo "git config --global user.signingkey: $(git config --global --get user.signingkey)"

echo "Staging all uncommitting changes to the repo at /gitrepo."
git add *

echo "Attempting to commit with the message: '$BCM_GIT_COMMIT_MESSAGE'"
git commit -a -m "$BCM_GIT_COMMIT_MESSAGE" --gpg-sign
