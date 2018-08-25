#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

lxc exec underlay -- mkdir -p /apps
lxc exec underlay -- mkdir -p /apps/bcm-base
lxc exec underlay -- docker pull ubuntu:bionic
lxc file push Dockerfile underlay/apps/bcm-base/Dockerfile
lxc exec underlay -- docker build -t bcm-base:latest /apps/bcm-base
