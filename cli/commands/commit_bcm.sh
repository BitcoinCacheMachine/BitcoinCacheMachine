#!/bin/bash

set -eu
cd "$(dirname "$0")"


COMMIT_MESSAGE=""

if [[ ! -z $1 ]]; then
    COMMIT_MESSAGE=$1
fi

# quit if a commit message wasn't passed.
if [[ $COMMIT_MESSAGE = "" ]]; then
    echo "Please provide a commit message."
    exit
fi

# get the latest commit
cd $BCM_LOCAL_GIT_REPO
export GIT_COMMIT_VERSION=$(git log --format="%H" -n 1)
cd -


bcm git commit -g=/home/derek/git/github/bcm -m="Updated CLI." -i=test -o=/home/derek/.gnupg -e=ubuntu@domain.com
