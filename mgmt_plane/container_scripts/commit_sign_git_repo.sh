#!/bin/bash

# set our working directory to the /gitrepo is which where out git repository
# should be mounted. This is what we're committing.
cd /gitrepo



git config --local commit.gpgsign 1
git config --local gpg.program $(which gpg2)
echo "git config --local commit.gpgsign:  $(git config --local --get commit.gpgsign)"
echo "git config --local gpg.program: $(git config --local --get gpg.program)"

git config --local user.name $BCM_GIT_CLIENT_USERNAME
echo "git config --local user.name set to '$(git config --local --get user.name)'"

# email must be passed in since a certificate can have many emails (uids)
git config --local user.email "$BCM_EMAIL_ADDRESS"
echo "git config --local user.email set to '$(git config --local --get user.email)'"

#gpg --list-secret-keys --keyid-format LONG
#git config --local user.signingkey 

echo "Staging all outstanding changes."
git add *

echo "Committing and signing. Get ready to check your Trezor."
echo "BCM_GIT_COMMIT_MESSAGE: '$BCM_GIT_COMMIT_MESSAGE'"
git commit -S -am "test" --gpg-sign
