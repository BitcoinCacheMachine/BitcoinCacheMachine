#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

lxc exec gateway -- mkdir -p /apps/tor
lxc file push Dockerfile gateway/apps/tor/Dockerfile
lxc exec gateway -- docker build -t bcm-tor:latest /apps/tor
