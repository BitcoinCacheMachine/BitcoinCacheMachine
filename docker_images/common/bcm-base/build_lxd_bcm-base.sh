#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

echo "Building 'bcm-base' docker image on LXC host '$1'."

lxc exec $1 -- mkdir -p /apps
lxc exec $1 -- mkdir -p /apps/bcm-base
lxc exec $1 -- docker pull ubuntu:bionic
lxc file push Dockerfile $1/apps/bcm-base/Dockerfile
lxc exec $1 -- docker build -t bcm-base:latest /apps/bcm-base
