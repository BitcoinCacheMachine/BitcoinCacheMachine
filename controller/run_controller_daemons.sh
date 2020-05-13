#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

# this script ensures that your management plane has a working IPFS mode
# this runs in docker on the front-end and is used for downloading and distributing
# bootstrap related data, e.g., LXC images, docker base images, etc; things that would
# benefit from IPFS integration.

docker image pull ipfs/go-ipfs

if docker ps | grep -q ipfs_host; then
    docker kill ipfs_host
fi

docker system prune -f

docker volume rm bcm_ipfs_staging
docker volume rm bcm_ipfs_data

docker volume create bcm_ipfs_staging
docker volume create bcm_ipfs_data

docker run -d \
--name ipfs_host \
-v ipfs_staging:/export \
-v ipfs_data:/data/ipfs \
-e IPFS_PROFILE=server \
-p 4001:4001 \
-p 127.0.0.1:8080:8080 \
-p 127.0.0.1:5001:5001 \
ipfs/go-ipfs:latest
