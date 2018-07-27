#!/bin/bash

rm -rf /tmp/proxyhost

lxc delete --force proxyhost

lxc network delete proxyhostnet

lxc profile delete proxyhostprofile

lxc storage delete proxyhost-dockervol
