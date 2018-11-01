#!/bin/bash

set -e

COMMIT_MESSAGE=""

if [[ ! -z $1 ]]; then
    COMMIT_MESSAGE=$1
fi

# quit if a commit message wasn't passed.
if [[ $COMMIT_MESSAGE = "" ]]; then
    echo "Please provide a commit message."
    exit
fi

cd $BCM_LOCAL_GIT_REPO
export GIT_COMMIT_VERSION=$(git log --format="%H" -n 1)
cd -

cd ~/.bcm
git add *
git commit -am "BCM_LOCAL_GIT_REPO version: $GIT_COMMIT_VERSION. Message: $COMMIT_MESSAGE"
cd -
