#!/bin/bash

cd $BCM_LOCAL_GIT_REPO
export GIT_COMMIT_VERSION=$(git log --format="%H" -n 1)
cd -

cd ~/.bcm
git add *
git commit -am "Committed ~/.bcm git repo. Latest BCM_LOCAL_GIT_REPO commit: $GIT_COMMIT_VERSION"
cd -
