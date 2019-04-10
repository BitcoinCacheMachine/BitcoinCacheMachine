#!/bin/bash

set -Eeu

LOCAL_GW_LXD_HOST_IP=
TOR_PROXY=
TOR_CONTROL=
OVERLAY_NETWORK_IP=

LOCAL_GW_LXD_HOST_IP="$(getent hosts "$LXC_HOSTNAME" | awk '{ print $1 }')"
echo "The IP address of the locally resident LXC '$LXC_HOSTNAME' host is '$LOCAL_GW_LXD_HOST_IP'"

TOR_PROXY="$LOCAL_GW_LXD_HOST_IP:9050"
TOR_CONTROL="$LOCAL_GW_LXD_HOST_IP:9051"

echo "Using '$TOR_PROXY' and '$TOR_CONTROL' for the TOR Proxy and TOR Control ports, respectively."

OVERLAY_NETWORK_IP=$(ip addr | grep "172.16.238." | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

export LOCAL_GW_LXD_HOST_IP="$LOCAL_GW_LXD_HOST_IP"
export TOR_PROXY="$TOR_PROXY"
export TOR_CONTROL="$TOR_CONTROL"
export OVERLAY_NETWORK_IP="$OVERLAY_NETWORK_IP"

# HOST_ENDING="$(echo "$DEFAULT_GATEWAY_HOSTNAME" | grep -Eo '[0-9]{1,2}')"
# LOCAL_GW_LXC_HOST="$LXC_HOSTNAME"
# DEFAULT_GATEWAY_IP="$(ip route | grep "default via" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')"
# DEFAULT_GATEWAY_HOSTNAME="$(host "$DEFAULT_GATEWAY_IP" | tail -n 1 | sed -e "s/^.* //;s/[[:punct:]]*$//")"
# echo "Docker container '$(hostname)' is scheduled on LXC host '$DEFAULT_GATEWAY_HOSTNAME'"

# export DEFAULT_GATEWAY_IP="$DEFAULT_GATEWAY_IP"
# export DEFAULT_GATEWAY_HOSTNAME="$DEFAULT_GATEWAY_HOSTNAME"
# export HOST_ENDING="$HOST_ENDING"