#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

echo "Deploying registry mirrors to the active LXD endpoint."
lxc exec $1 -- mkdir -p /apps/registry_mirror
lxc file push registry_mirror.yml $1/apps/registry_mirror/registry_mirror.yml
lxc exec $1 -- docker stack deploy -c /apps/registry_mirror/registry_mirror.yml registrymirror
