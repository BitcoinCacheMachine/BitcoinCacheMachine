#!/bin/bash

# usage: './update.sh --commit-push --commit-message="message"'

set -Eeuo pipefail
cd "$(dirname "$0")"

COMMIT_PUSH=0
COMMIT_MESSAGE=

for i in "$@"; do
    case $i in
        --commit-push)
            COMMIT_PUSH=1
            shift # past argument=value
        ;;
        --commit-message=*)
            COMMIT_MESSAGE="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

# let's pull any changes from the upstream repo
git fetch upstream

# pull latest HEAD from BitcoinCacheMachine/BitcoinCacheMachine
git pull upstream master

# if the user want's to commit the currently staged files and perform a push
# to the origin/master.
if [ $COMMIT_PUSH = 1 ]; then
    
    # TODO check for user.name and user.email and commit-sign key, etc.
    # TODO write guidance on setting required variables and having GPG up on GITHUB
    git commit -S --message="$COMMIT_MESSAGE"
    
    # we first pull from the remote to ensure we are at the same HEAD. This could happen if you
    # created a local commit, then undid it, then re-committed.
    git pull
    
    # push the new commit up to origin/master
    # Note all PULLS are based on the upstream git remote BitcoinCacheMachine/BitcoinCacheMachine
    git push origin master
fi