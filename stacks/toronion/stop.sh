#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

lxc exec "$BCM_MANAGER_HOST_NAME" -- docker stack remove toronion

# this gets called to clean up anything stack specific. In this case, we run bcm ssh remove-onion
bcm ssh remove-onion --title="$(lxc remote get-default)"

sleep 10

lxc exec "$BCM_UNDERLAY_HOST_NAME" -- docker volume rm toronion_data
lxc exec "$BCM_UNDERLAY_HOST_NAME" -- docker volume rm toronion_logs
