#!/bin/bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

# build the necessary images
bash -c $BCM_LOCAL_GIT_REPO/docker_images/underlay/build_underlay.sh

#systemd binds to 53 be default, remove it and let's use docker-hosted dnsmasq container
lxc exec underlay -- systemctl stop systemd-resolved
lxc exec underlay -- systemctl disable systemd-resolved

lxc exec underlay -- docker run --name dnsmasq -d --restart always --net=host --cap-add=NET_ADMIN bcm-dnsmasq:latest

# TODO - find a way to get dockerd to run WITHOUT systemd-resolved


