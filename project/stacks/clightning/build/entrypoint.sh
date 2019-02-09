#!/bin/bash

set -Eeuo pipefail

source /bcm/proxy_ip_determinant.sh

echo "BCM /entrypoint.sh for clightning"


#TODO we need to remove TOR lcoally and use the remove gateway host, but CLIGHTNING doesn't support this yet
# so we have to use a local TOR instance.

# TOR_PROXY="127.0.0.1:9050"
# TOR_CONTROL_HOST="127.0.0.1:9051"

# /usr/bin/tor -f /etc/tor/torrc &

# sleep 30

wait-for-it -t 10 "$TOR_PROXY"
wait-for-it -t 10 "$TOR_CONTROL_HOST"

# wait for the managementt plane.
bash -c "/bcm/wait_for_gogo.sh --gogofile=/root/.lightning/gogo"

#sleep 160

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
