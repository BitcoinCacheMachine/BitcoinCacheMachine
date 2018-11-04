#!/usr/bin/env bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

lxc exec $1 -- mkdir -p /apps/tor
lxc file push Dockerfile $1/apps/tor/Dockerfile
lxc exec $1 -- docker build -t bcm-tor:latest /apps/tor
