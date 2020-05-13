#!/bin/bash


set -Eeuox pipefail
cd "$(dirname "$0")"

source ./env

# let's pull any changes from the upstream repo
git fetch upstream

# pull latest HEAD.
git pull upstream master
