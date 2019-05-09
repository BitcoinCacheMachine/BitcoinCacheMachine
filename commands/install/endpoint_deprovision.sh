#!/bin/bash

set -Eeux

if lxc profile list --format csv | grep "default" | grep -q ",0" ; then
    lxc profile delete default
fi

# shutdown all LXD containers and quit lxd
sudo lxd shutdown

# remove lxd
sudo snap remove lxd
