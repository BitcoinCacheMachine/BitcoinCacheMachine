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


ASSUME_VALID_BLOCK_HASH="000000000000000000200dae629d608a24fcaf4f564f9b39ea517858dabf2238"
if [[ $BCM_ACTIVE_CHAIN == "testnet" ]]; then
    BITCOIND_CHAIN_TEXT="-testnet"
    MEM_POOL_SIZE=300
    MAX_UPLOAD_TARGET=5
    P2P_PORT=18333
    ASSUME_VALID_BLOCK_HASH="000000000000018988103eae5d6b0ae47afcc444fc6ab93ee0cf6000512ed6aa"
    echo "testnet=1" >> /root/.bitcoin/bitcoin.conf
    elif [[ $BCM_ACTIVE_CHAIN == "regtest" ]]; then
    BITCOIND_CHAIN_TEXT="-regtest"
    MEM_POOL_SIZE=30
    MAX_UPLOAD_TARGET=2
    P2P_PORT=28333
    ASSUME_VALID_BLOCK_HASH=0
    echo "regtest=1" >> /root/.bitcoin/bitcoin.conf
fi


ip route

ip addr

RPCNET_SUBNET_PREFIX="${BITCOIND_RPCNET_SUBNET%.*}"
BITCOIND_RPCNET_IP="$(ip addr | grep "$RPCNET_SUBNET_PREFIX" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")"

ONIONNET_SUBNET_PREFIX="${BITCOIND_ONIONNET_SUBNET%.*}"
BITCOIND_ONIONNET_IP="$(ip addr | grep "$ONIONNET_SUBNET_PREFIX" | grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b")"

{
    echo "rpcbind=$BITCOIND_RPCNET_IP:$BITCOIND_RPC_PORT"
    echo "rpcallowip=$BITCOIND_RPCNET_SUBNET"
    echo "zmqpubrawblock=tcp://$BITCOIND_RPCNET_IP:$BITCOIND_ZMQ_BLOCK_PORT"
    echo "zmqpubrawtx=tcp://$BITCOIND_RPCNET_IP:$BITCOIND_ZMQ_TX_PORT"
} >> /root/.bitcoin/bitcoin.conf

echo "$BITCOIND_RPCNET_IP:$BITCOIND_RPC_PORT" > /root/.bitcoin/rpcip.txt

# We'll do some extra configuration steps if we're in IDB
BITCOIND_DBCACHE=300
if [[ $INITIAL_BLOCK_DOWNLOAD == 1 ]]; then
    BITCOIND_DBCACHE=2048
fi


exec bitcoind -conf=/root/.bitcoin/bitcoin.conf \
-datadir=/root/.bitcoin \
-proxy="$TOR_PROXY" \
-torcontrol="$TOR_CONTROL" \
-proxyrandomize=1 \
-zmqpubrawblock="tcp://$BITCOIND_RPCNET_IP:$BITCOIND_ZMQ_BLOCK_PORT" \
-zmqpubrawblock="tcp://$BITCOIND_ONIONNET_IP:$BITCOIND_ZMQ_BLOCK_PORT" \
-zmqpubrawtx="tcp://$BITCOIND_RPCNET_IP:$BITCOIND_ZMQ_TX_PORT" \
-zmqpubrawtx="tcp://$BITCOIND_ONIONNET_IP:$BITCOIND_ZMQ_TX_PORT" \
-rpcallowip="127.0.0.0/8" \
-rpcallowip="$BITCOIND_RPCNET_SUBNET" \
-rpcallowip="$BITCOIND_ONIONNET_SUBNET" \
-rpcbind="$BITCOIND_RPCNET_IP:$BITCOIND_RPC_PORT" \
-rpcbind="$BITCOIND_ONIONNET_IP:$BITCOIND_RPC_PORT" \
-rpcbind="127.0.0.1:$BITCOIND_RPC_PORT" \
-wallet="/bitcoin/wallet" \
-dbcache="$BITCOIND_DBCACHE" \
-assumevalid="$ASSUME_VALID_BLOCK_HASH" \
-maxmempool="$MEM_POOL_SIZE" \
-maxuploadtarget="$MAX_UPLOAD_TARGET" \
-bind="$BITCOIND_RPCNET_IP" \
-bind="$BITCOIND_ONIONNET_IP" \
-port="$P2P_PORT" \
-debug=tor "$BITCOIND_CHAIN_TEXT"
