#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

# determine if we need to build the image.
if [[ $BCS_INSTALL_RSYNCD_BUILD = "true" ]]; then
    echo "Building and pushing $BCS_INSTALL_RSYNCD_BUILD_IMAGE to the private registry hosted on 'cachestack'."

    lxc exec cachestack -- mkdir -p /apps/rsyncd
    lxc file push ./Dockerfile cachestack/apps/rsyncd/Dockerfile
    lxc file push ./rsyncd.conf cachestack/apps/rsyncd/rsyncd.conf

    lxc exec cachestack -- docker build -t "$BCS_INSTALL_RSYNCD_BUILD_IMAGE" /apps/rsyncd
    lxc exec cachestack -- docker push "$BCS_INSTALL_RSYNCD_BUILD_IMAGE"
fi

echo "Deploying docker rsyncd to the Cache Stack."
lxc exec cachestack -- mkdir -p /apps/rsyncd
lxc file push ./rsyncd.yml cachestack/apps/rsyncd/rsyncd.yml
lxc exec cachestack -- docker stack deploy -c /apps/rsyncd/rsyncd.yml rsyncd