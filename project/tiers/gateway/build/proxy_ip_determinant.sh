#!/bin/bash

set -Eeu

DEFAULT_GATEWAY_IP=
DEFAULT_GATEWAY_HOSTNAME=
HOST_ENDING=
LOCAL_GW_LXD_HOST_IP=
TOR_PROXY=
TOR_CONTROL_HOST=
OVERLAY_NETWORK_IP=

DEFAULT_GATEWAY_IP="$(ip route | grep "default via" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')"
DEFAULT_GATEWAY_HOSTNAME="$(host "$DEFAULT_GATEWAY_IP" | tail -n 1 | sed -e "s/^.* //;s/[[:punct:]]*$//")"
echo "Docker container '$(hostname)' is scheduled on LXC host '$DEFAULT_GATEWAY_HOSTNAME'"

HOST_ENDING="$(echo "$DEFAULT_GATEWAY_HOSTNAME" | grep -Eo '[0-9]{1,2}')"
LOCAL_GW_LXC_HOST="bcm-gateway-$HOST_ENDING"
LOCAL_GW_LXD_HOST_IP="$(getent hosts "$LOCAL_GW_LXC_HOST" | awk '{ print $1 }')"
echo "The IP address of the locally resident LXC '$LOCAL_GW_LXC_HOST' host is '$LOCAL_GW_LXD_HOST_IP'"

TOR_PROXY="$LOCAL_GW_LXD_HOST_IP:9050"
TOR_CONTROL_HOST="$LOCAL_GW_LXD_HOST_IP:9051"

echo "Using '$TOR_PROXY' and '$TOR_CONTROL_HOST' for the TOR Proxy and TOR Control ports, respectively."

# TODO make this cleaner.
OVERLAY_NETWORK_IP=$(ip addr | grep "172.16.238." | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')


export DEFAULT_GATEWAY_IP="$DEFAULT_GATEWAY_IP"
export DEFAULT_GATEWAY_HOSTNAME="$DEFAULT_GATEWAY_HOSTNAME"
export HOST_ENDING="$HOST_ENDING"
export LOCAL_GW_LXD_HOST_IP="$LOCAL_GW_LXD_HOST_IP"
export TOR_PROXY="$TOR_PROXY"
export TOR_CONTROL_HOST="$TOR_CONTROL_HOST"
export OVERLAY_NETWORK_IP="$OVERLAY_NETWORK_IP"