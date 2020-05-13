#!/bin/bash


set -Eeuox pipefail
cd "$(dirname "$0")"

source ./env

# let's pull any changes from the upstream repo
#git fetch upstream


# first, let's commit and push our changes, so that the new VM will
# pull git from the published location. Note we do NOT mount BCM_GIT_DIR
# from the controller; it's always pulled from the GIT server endpoint
git add *
git commit -S --message="automated commit push."
git push