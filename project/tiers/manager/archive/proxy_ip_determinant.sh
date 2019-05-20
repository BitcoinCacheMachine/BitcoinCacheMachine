#!/bin/bash

set -Eeu

LOCAL_GW_LXD_HOST_IP=
TOR_PROXY=
TOR_CONTROL=
#OVERLAY_NETWORK_IP=

LOCAL_GW_LXD_HOST_IP="$(getent hosts torsocks | awk '{ print $1 }')"
echo "The IP address of the locally resident LXC '$LXC_HOSTNAME' host is '$LOCAL_GW_LXD_HOST_IP'"

TOR_PROXY="$LOCAL_GW_LXD_HOST_IP:9050"
TOR_CONTROL="$LOCAL_GW_LXD_HOST_IP:9051"

echo "Using '$TOR_PROXY' and '$TOR_CONTROL' for the TOR Proxy and TOR Control ports, respectively."

OVERLAY_NETWORK_IP=$(ip addr | grep "172.16.238." | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

export LOCAL_GW_LXD_HOST_IP="$LOCAL_GW_LXD_HOST_IP"
export TOR_PROXY="$TOR_PROXY"
export TOR_CONTROL="$TOR_CONTROL"
export OVERLAY_NETWORK_IP="$OVERLAY_NETWORK_IP"
