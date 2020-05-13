#!/bin/bash


set -Eeuo pipefail
cd "$(dirname "$0")"

# let's pull any changes from the upstream repo
git fetch upstream

# pull latest HEAD from BitcoinCacheMachine/BitcoinCacheMachine
git pull upstream master
