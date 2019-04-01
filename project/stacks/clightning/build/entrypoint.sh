#!/bin/bash

set -Eeuo pipefail


source /bcm/proxy_ip_determinant.sh --host-ending="$LXC_HOSTNAME"


echo "BCM /entrypoint.sh for clightning"

wait-for-it -t 10 "$TOR_PROXY"
wait-for-it -t 10 "$TOR_CONTROL_HOST"

if [[ ! -z "$CHAIN" ]]; then
    if [[ $CHAIN == "testnet" ]]; then
        wait-for-it -t 300 bitcoindrpc-testnet:18332
        /root/lightning/lightningd/lightningd --conf=/root/.lightning/config --proxy="$TOR_PROXY" --addr="autotor:$TOR_CONTROL_HOST"
    fi
else
    echo "Error: CHAIN not set."
fi


#--bind-addr="127.0.0.1:9735"
#-proxy="$TOR_PROXY" -torcontrol="$TOR_CONTROL_HOST" -rpcbind="$OVERLAY_NETWORK_IP" -zmqpubrawblock="tcp://$OVERLAY_NETWORK_IP:28332" -zmqpubrawtx="tcp://$OVERLAY_NETWORK_IP:28332"
#/root/lightning/lightningd/lightningd --conf=/root/.lightning/config --proxy="$TOR_PROXY" --addr="autotor:$TOR_CONTROL_HOST"
#--proxy="$TOR_PROXY" --addr="autotor:$TOR_CONTROL_HOST"

#--tor-service-password=password --log-level=debug
# elif [[ $CHAIN == "mainnet" ]]; then
# /root/lightning/lightningd/lightningd --conf=/root/.lightning/config --proxy="$TOR_PROXY" --addr="autotor:$TOR_CONTROL_HOST" --tor-service-password=password --log-level=debug
