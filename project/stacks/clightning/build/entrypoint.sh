#!/bin/bash

set -Eeuo pipefail

# shellcheck disable=SC1091
source /bcm/proxy_ip_determinant.sh

echo "BCM /entrypoint.sh for clightning"

wait-for-it -t 10 "$TOR_PROXY"
wait-for-it -t 10 "$TOR_CONTROL_HOST"

# wait for the managementt plane.
bash -c "/bcm/wait_for_gogo.sh --gogofile=/root/.lightning/gogo"

if [[ ! -z "$CHAIN" ]]; then
    if [[ $CHAIN == "testnet" ]]; then
        #--bind-addr="127.0.0.1:9735"
        #-proxy="$TOR_PROXY" -torcontrol="$TOR_CONTROL_HOST" -rpcbind="$OVERLAY_NETWORK_IP" -zmqpubrawblock="tcp://$OVERLAY_NETWORK_IP:28332" -zmqpubrawtx="tcp://$OVERLAY_NETWORK_IP:28332"
        /root/lightning/lightningd/lightningd --conf=/root/.lightning/config --proxy="$TOR_PROXY" --addr="autotor:$TOR_CONTROL_HOST"
        #/root/lightning/lightningd/lightningd --conf=/root/.lightning/config --proxy="$TOR_PROXY" --addr="autotor:$TOR_CONTROL_HOST"
        #--proxy="$TOR_PROXY" --addr="autotor:$TOR_CONTROL_HOST"
        
        #--tor-service-password=password --log-level=debug
        # elif [[ $CHAIN == "mainnet" ]]; then
        # /root/lightning/lightningd/lightningd --conf=/root/.lightning/config --proxy="$TOR_PROXY" --addr="autotor:$TOR_CONTROL_HOST" --tor-service-password=password --log-level=debug
    fi
else
    echo "Error: CHAIN not set."
fi
