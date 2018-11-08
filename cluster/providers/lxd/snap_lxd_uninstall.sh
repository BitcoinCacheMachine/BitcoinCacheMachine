#!/bin/bash

if [[ ! -z $(sudo snap list | grep lxd) ]]; then
    sudo snap remove lxd
fi