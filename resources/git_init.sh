#!/bin/bash

set -Eeuo pipefail

# get the codename, usually bionic or debian
CODE_NAME="$(< /etc/os-release grep VERSION_CODENAME | cut -d "=" -f 2)"

# add the tor apt repository
echo "deb https://deb.torproject.org/torproject.org $CODE_NAME main" | sudo tee -a /etc/apt/sources.list
echo "deb-src https://deb.torproject.org/torproject.org $CODE_NAME main" | sudo tee -a /etc/apt/sources.list

# download the tor PGP key and add it as a trusted key to apt
curl https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | sudo gpg --import
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add -

# update apt and install pre-reqs
sudo apt-get update
sudo apt-get install -y tor curl wait-for-it git deb.torproject.org-keyring

# wait for local tor to come online.
wait-for-it -t 30 127.0.0.1:9050

# configure git to download through the local tor proxy.
BCM_GITHUB_REPO_URL="https://github.com/BitcoinCacheMachine/BitcoinCacheMachine"
git config --global http.$BCM_GITHUB_REPO_URL.proxy socks5://127.0.0.1:9050

# clone the BCM repo to $HOME/git/github/bcm
BCM_GIT_DIR="$HOME/git/github/bcm"
git clone "$BCM_GITHUB_REPO_URL" "$BCM_GIT_DIR"

# run bcm command to init the rest
bash -c "$BCM_GIT_DIR/bcm"
