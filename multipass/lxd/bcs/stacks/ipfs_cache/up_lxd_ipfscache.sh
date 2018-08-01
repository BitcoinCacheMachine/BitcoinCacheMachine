#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

echo "Deploying docker ipfs cache to the Cache Stack."
lxc exec cachestack -- mkdir -p /apps/ipfscache
lxc file push ./ipfs_cache.yml cachestack/apps/ipfscache/ipfscache.yml
lxc exec cachestack -- docker stack deploy -c /apps/ipfscache/ipfscache.yml ipfscache