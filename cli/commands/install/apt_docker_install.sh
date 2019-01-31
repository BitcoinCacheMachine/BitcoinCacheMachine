#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

sudo apt-get remove docker docker-engine docker.io containerd runc
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo apt-key fingerprint 0EBFCD88

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get update

sudo apt-get install -y docker-ce
# if the lxd groups doesn't exist, create it.
if ! grep -q docker /etc/group; then
    sudo addgroup docker
fi

if groups "$USER" | grep -q docker; then
    sudo usermod -aG docker $USER
fi
