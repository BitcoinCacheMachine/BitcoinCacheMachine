#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

sudo apt-get update
sudo apt-get install -y tor git
BCM_GITHUB_REPO_URL="https://github.com/BitcoinCacheMachine/BitcoinCacheMachine"
git config --global http.$BCM_GITHUB_REPO_URL.proxy socks5://localhost:9050

export BCM_GIT_DIR="$HOME/git/github/bcm"
mkdir -p "$BCM_GIT_DIR"
cd "$BCM_GIT_DIR"

if [ -d $BCM_GIT_DIR/.git ]; then
    git pull
else
    git clone "$BCM_GITHUB_REPO_URL" "$BCM_GIT_DIR"
fi

# we executed .bcm the first time so it'll updated ~/.bashrc
./bcm