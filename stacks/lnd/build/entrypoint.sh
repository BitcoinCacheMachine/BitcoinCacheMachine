#!/bin/bash

set -Eeuo pipefail

# torsocks is the network alias for the tor SOCKS proxy on the docker overlay network.
TOR_HOST_IP="$(getent hosts torsocks | awk '{ print $1 }')"
TOR_PROXY="$TOR_HOST_IP:9050"
TOR_CONTROL="$TOR_HOST_IP:9051"
TOR_DNS="$TOR_HOST_IP:9053"

OVERLAY_IP=$(ip addr | grep "172.16.240." | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

# copy the base config from /secrets/lnd.conf, then add runtime-specific items.
# the updated config may be required by downstream components.
CONF_PATH=/root/.lnd/lnd.conf
cp /secrets/lnd.conf "$CONF_PATH"
RPC_IP=$(</root/.bitcoin/rpcip.txt)

{
    echo "restlisten=$OVERLAY_IP:8080"
    
    echo "[Bitcoin]"
    echo "bitcoin.node=bitcoind"
    echo "bitcoin.active=1"
    
    echo "[Bitcoind]"
    echo "bitcoin.rpchost=$RPC_IP"
    echo "bitcoin.dir=/root/.bitcoin"
    
    echo "[tor]"
    echo "tor.active=1"
    echo "tor.v3=1"
    echo "tor.socks=$TOR_PROXY"
    echo "tor.control=$TOR_CONTROL"
    echo "tor.streamisolation=1"
    echo "tor.dns=soa.nodes.lightning.directory:53"
    echo "tor.privatekeypath=/root/.lnd/tor"
} >> "$CONF_PATH"


lnd --lnddir=/root/.lnd --configfile=/root/.lnd/lnd.conf "$CHAIN_TEXT"

#--listen=localhost \
#--bitcoin.node="bitcoind" \
#--bitcoind.rpchost="$RPC_IP" \
#--tor.socks="$TOR_PROXY" \
#--tor.control="$TOR_CONTROL" \
#--tor.dns="soa.nodes.lightning.directory:53" \
#--tor.streamisolation \
#--adminmacaroonpath="/root/.lnd_admin_macaroon/admin.macaroon" \
#--readonlymacaroonpath="/root/.lnd_readonly_macaroon/readonly.macaroon" \
#--logdir="/var/logs/lnd" \
#--bitcoind.dir="/root/.bitcoin" \
#--tor.v3 \