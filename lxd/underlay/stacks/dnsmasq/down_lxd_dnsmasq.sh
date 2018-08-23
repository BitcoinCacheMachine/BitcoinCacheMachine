#!/bin/bash

if [[ $(lxc list | grep underlay) ]]; then
    if [[ $(lxc exec underlay -- docker ps | grep dnsmasq) ]]; then
        lxc exec underlay -- docker kill dnsmasq
        lxc exec underlay -- docker system prune -f
    fi
fi