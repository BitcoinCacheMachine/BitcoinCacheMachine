#!/bin/bash

set -Eeux

echo "CHAIN: $CHAIN"
DEFAULT_GATEWAY="$(ip route | grep "default via" | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')"
DEFAULT_GATEWAY_HOSTNAME="$(host "$DEFAULT_GATEWAY" | tail -n 1 | sed -e "s/^.* //;s/[[:punct:]]*$//")"
HOST_ENDING="$(echo "$DEFAULT_GATEWAY_HOSTNAME" | grep -Eo '[0-9]{1,2}')"

LOCAL_GW_LXC_HOST="bcm-gateway-$HOST_ENDING"
LOCAL_GW_LXD_HOST_IP="$(getent hosts "$LOCAL_GW_LXC_HOST" | awk '{ print $1 }')"

TOR_PROXY="$LOCAL_GW_LXD_HOST_IP:9050"
TOR_CONTROL_HOST="$LOCAL_GW_LXD_HOST_IP:9051"

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
    sleep 2
    echo "."
done

if [[ $CHAIN == "testnet" ]]; then
    bitcoind -testnet -conf=/root/.bitcoin/bitcoin.conf -datadir=/root/.bitcoin -proxy="$TOR_PROXY" -torcontrol="$TOR_CONTROL_HOST" -rpcbind="$OVERLAY_NETWORK_IP" -zmqpubrawblock="tcp://$OVERLAY_NETWORK_IP:28332" -zmqpubrawtx="tcp://$OVERLAY_NETWORK_IP:28332" -debug=tor
    elif [[ $CHAIN == "mainnet" ]]; then
    bitcoind -conf=/root/.bitcoin/bitcoin.conf -datadir=/root/.bitcoin -proxy="$TOR_PROXY" -torcontrol="$TOR_CONTROL_HOST" -rpcbind="$OVERLAY_NETWORK_IP" -zmqpubrawblock="tcp://$OVERLAY_NETWORK_IP:28332" -zmqpubrawtx="tcp://$OVERLAY_NETWORK_IP:28332" -debug=tor
fi