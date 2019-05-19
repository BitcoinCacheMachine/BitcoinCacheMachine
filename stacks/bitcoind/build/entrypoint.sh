#!/bin/bash

set -Eeux

if [[ -z $BITCOIND_RPC_PORT ]]; then
    echo "ERROR: BITCOIND_RPC_PORT was not defined."
    exit
fi

# torsocks is the network alias for the tor SOCKS proxy on the docker overlay network.
TOR_HOST_IP="$(getent hosts torsocks | awk '{ print $1 }')"
TOR_PROXY="$TOR_HOST_IP:9050"
TOR_CONTROL="$TOR_HOST_IP:9051"
OVERLAY_NETWORK_IP="172.16.238.3"
OVERLAY_ONION_IP="172.16.200.6"

wait-for-it -t 10 "$TOR_PROXY"
wait-for-it -t 10 "$TOR_CONTROL"

# let's copy the base config from the stack.
# We can then append runtime-specific values.
cp /config/bitcoin.conf /root/.bitcoin/bitcoin.conf
chown root:root /root/.bitcoin/bitcoin.conf
chmod 0400 /root/.bitcoin/bitcoin.conf
chown -R root:root /root/.bitcoin

touch /root/.bitcoin/rpcip.txt
chmod 0400 /root/.bitcoin/bitcoin.conf
chown -R root:root /root/.bitcoin


BITCOIND_CHAIN_TEXT=
MEM_POOL_SIZE=600
MAX_UPLOAD_TARGET=10
P2P_PORT=8333
BITCOIND_ZMQ_BLOCK_PORT=9332
BITCOIND_ZMQ_TX_PORT=9331
ASSUME_VALID_BLOCK_HASH="000000000000000000200dae629d608a24fcaf4f564f9b39ea517858dabf2238"
if [[ $BCM_ACTIVE_CHAIN == "testnet" ]]; then
    BITCOIND_CHAIN_TEXT="-testnet"
    MEM_POOL_SIZE=300
    MAX_UPLOAD_TARGET=5
    P2P_PORT=18333
    BITCOIND_ZMQ_BLOCK_PORT=19332
    BITCOIND_ZMQ_TX_PORT=19331
    ASSUME_VALID_BLOCK_HASH="000000000000018988103eae5d6b0ae47afcc444fc6ab93ee0cf6000512ed6aa"
    echo "testnet=1" >> /root/.bitcoin/bitcoin.conf
    elif [[ $BCM_ACTIVE_CHAIN == "regtest" ]]; then
    BITCOIND_CHAIN_TEXT="-regtest"
    MEM_POOL_SIZE=30
    MAX_UPLOAD_TARGET=2
    P2P_PORT=28333
    BITCOIND_ZMQ_BLOCK_PORT=29332
    BITCOIND_ZMQ_TX_PORT=29331
    ASSUME_VALID_BLOCK_HASH=0
    echo "regtest=1" >> /root/.bitcoin/bitcoin.conf
fi

{
    echo "rpcbind=$OVERLAY_NETWORK_IP:$BITCOIND_RPC_PORT"
    echo "rpcallowip=172.16.238.0/24"
    echo "zmqpubrawblock=tcp://$OVERLAY_NETWORK_IP:$BITCOIND_ZMQ_BLOCK_PORT"
    echo "zmqpubrawtx=tcp://$OVERLAY_NETWORK_IP:$BITCOIND_ZMQ_TX_PORT"
} >> /root/.bitcoin/bitcoin.conf

echo "$OVERLAY_NETWORK_IP:$BITCOIND_RPC_PORT" > /root/.bitcoin/rpcip.txt

# We'll do some extra configuration steps if we're in IDB
BITCOIND_DBCACHE=300
if [[ $INITIAL_BLOCK_DOWNLOAD == 1 ]]; then
    BITCOIND_DBCACHE=2048
fi

# run bitcoind
bitcoind -conf=/root/.bitcoin/bitcoin.conf \
-datadir=/root/.bitcoin \
-proxy="$TOR_PROXY" \
-torcontrol="$TOR_CONTROL" \
-proxyrandomize=1 \
-zmqpubrawblock="tcp://$OVERLAY_NETWORK_IP:$BITCOIND_ZMQ_BLOCK_PORT" \
-zmqpubrawblock="tcp://$OVERLAY_ONION_IP:$BITCOIND_ZMQ_BLOCK_PORT" \
-zmqpubrawtx="tcp://$OVERLAY_NETWORK_IP:$BITCOIND_ZMQ_TX_PORT" \
-zmqpubrawtx="tcp://$OVERLAY_ONION_IP:$BITCOIND_ZMQ_TX_PORT" \
-rpcallowip="127.0.0.0/8" \
-rpcallowip="172.16.238.0/24" \
-rpcallowip="172.16.200.0/24" \
-rpcbind="$OVERLAY_NETWORK_IP:$BITCOIND_RPC_PORT" \
-rpcbind="$OVERLAY_ONION_IP:$BITCOIND_RPC_PORT" \
-rpcbind="127.0.0.1:$BITCOIND_RPC_PORT" \
-wallet="/bitcoin/wallet" \
-dbcache="$BITCOIND_DBCACHE" \
-assumevalid="$ASSUME_VALID_BLOCK_HASH" \
-maxmempool="$MEM_POOL_SIZE" \
-maxuploadtarget="$MAX_UPLOAD_TARGET" \
-bind="$OVERLAY_NETWORK_IP" \
-bind="$OVERLAY_ONION_IP" \
-port="$P2P_PORT" \
-debug=tor "$BITCOIND_CHAIN_TEXT"
