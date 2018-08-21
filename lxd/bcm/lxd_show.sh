#!/bin/bash

echo "lxc hosts"
lxc list 

echo "lxc networks"
lxc network list 

echo "lxc profiles"
lxc profile list 

echo "lxc storage list"
lxc storage list 

echo "lxc remote list"
lxc remote list