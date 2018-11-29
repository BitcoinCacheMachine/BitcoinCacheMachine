#!/bin/bash

set -Eeuo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get install -y wait-for-it host

wait-for-it -t 120 127.0.10.1:9050

sleep 15


host -v archive.ubuntu.com

sleep 10

#export HTTP_PROXY=http://127.0.10.1:9050
#export HTTPS_PROXY=http://127.0.10.1:9050

apt-get install -y wait-for-it git iproute2 wget curl

 





# docker exec -t wasabi wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
# docker exec -t wasabi dpkg -i packages-microsoft-prod.deb
# docker exec -t wasabi apt-get install apt-transport-https
# docker exec -t wasabi apt-get update
# docker exec -t wasabi apt-get install -y dotnet-sdk-2.1

# WASABI_GITHUB_URL=https://github.com/zkSNACKs/WalletWasabi

# docker exec -t -e WASABI_GITHUB_URL=$WASABI_GITHUB_URL wasabi git config --global http.$WASABI_GITHUB_URL.proxy socks5://127.0.10.1:9050

# docker exec -t -e WASABI_GITHUB_URL=$WASABI_GITHUB_URL wasabi git clone $WASABI_GITHUB_URL --recursive /wasabigitrepo/

# docker exec -t -e WASABI_GITHUB_URL=$WASABI_GITHUB_URL wasabi git pull




