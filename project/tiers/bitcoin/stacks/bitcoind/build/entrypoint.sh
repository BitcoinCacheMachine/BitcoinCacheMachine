#!/bin/bash

set -Eeu

echo "CHAIN: $CHAIN"
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


wait-for-it -t 10 "$TOR_PROXY"
wait-for-it -t 10 "$TOR_CONTROL_HOST"

GOGO_FILE=
if [[ $CHAIN == "testnet" ]]; then
    GOGO_FILE=/data/testnet3/gogogo
    elif [[ $CHAIN == "mainnet" ]]; then
    GOGO_FILE=/data/gogogo
else
    echo "Error: CHAIN must be either 'testnet' or 'mainnet'."
    exit
fi

# we are going to wait for GOGO_FILE to appear before starting bitcoind.
# this allows the management plane to upload the blocks and/or chainstate.
while [ ! -f "$GOGO_FILE" ]
do
    sleep .5
    printf '.'
done

if [[ $CHAIN == "testnet" ]]; then
    bitcoind -conf=/root/.bitcoin/bitcoin.conf -datadir=/root/.bitcoin -proxy="$TOR_PROXY" -torcontrol="$TOR_CONTROL_HOST" -rpcbind="$OVERLAY_NETWORK_IP" -zmqpubrawblock="tcp://$OVERLAY_NETWORK_IP:28332" -zmqpubrawtx="tcp://$OVERLAY_NETWORK_IP:28332" -debug=tor -testnet
    elif [[ $CHAIN == "mainnet" ]]; then
    bitcoind -conf=/root/.bitcoin/bitcoin.conf -datadir=/root/.bitcoin -proxy="$TOR_PROXY" -torcontrol="$TOR_CONTROL_HOST" -rpcbind="$OVERLAY_NETWORK_IP" -zmqpubrawblock="tcp://$OVERLAY_NETWORK_IP:28332" -zmqpubrawtx="tcp://$OVERLAY_NETWORK_IP:28332" -debug=tor
fi