#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

echo "Deploying docker torSOCKS5proxy to the Cache Stack."
lxc exec cachestack -- mkdir -p /apps/tor_socks5_proxy
lxc file push ./tor_socks5_proxy.yml cachestack/apps/tor_socks5_proxy/tor_socks5_proxy.yml
lxc exec cachestack -- docker stack deploy -c /apps/tor_socks5_proxy/tor_socks5_proxy.yml torSOCKS5proxy
