#!/bin/bash

set -Eeux

if lxc profile list --format csv | grep "default" | grep -q ",0" ; then
    lxc profile delete default
fi



