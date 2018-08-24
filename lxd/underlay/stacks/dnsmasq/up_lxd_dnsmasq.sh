#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

echo "Building local image for running 'underlay' services."

lxc exec underlay -- docker pull ubuntu:bionic
lxc exec underlay -- mkdir -p /apps/dnsmasq
lxc file push ./Dockerfile underlay/apps/dnsmasq/Dockerfile
lxc file push ./dnsmasq.conf underlay/apps/dnsmasq/dnsmasq.conf
lxc exec underlay -- docker build -t dnsmasq:latest /apps/dnsmasq

# systemd binds to 53 be default, remove it and let's use docker-hosted dnsmasq container
lxc exec underlay -- systemctl stop systemd-resolved
lxc exec underlay -- systemctl disable systemd-resolved

sleep 10

lxc exec underlay -- docker run --name dnsmasq --rm -d --cap-add=NET_ADMIN --net=host dnsmasq:latest dnsmasq -d

lxc exec underlay -- ifmetric eth1 25
