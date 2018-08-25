#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

lxc exec underlay -- mkdir -p /apps/tor
lxc file push Dockerfile underlay/apps/tor/Dockerfile
lxc exec underlay -- docker build -t bcm-tor:latest /apps/tor
