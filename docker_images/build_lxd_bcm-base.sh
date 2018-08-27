#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

lxc exec gateway -- mkdir -p /apps
lxc exec gateway -- mkdir -p /apps/bcm-base
lxc exec gateway -- docker pull ubuntu:bionic
lxc file push Dockerfile gateway/apps/bcm-base/Dockerfile
lxc exec gateway -- docker build -t bcm-base:latest /apps/bcm-base
