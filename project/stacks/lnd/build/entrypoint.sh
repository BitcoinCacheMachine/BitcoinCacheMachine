#!/bin/bash

set -Eeuox pipefail

# error function is used within a bash function in order to send the error
# message directly to the stderr output and exit.
error() {
    echo "$1" >/dev/stderr
    exit 0
}

# return is used within bash function in order to return the value.
return() {
    echo "$1"
}

BITCOIND_RPC_PORT="8332"
BITCOIND_ZMQ_PORT="9332"
COMMAND_TEXT="--bitcoin.mainnet"
BITCOIND_ZMQ_BLOCK_PORT=
BITCOIND_ZMQ_TX_PORT=

# mainnet ZMQ, testnet ZMQ, regtest ZMQ
EXPOSE 9332 19332 29332
if [[ $CHAIN == "testnet" ]]; then
    BITCOIND_RPC_PORT=18332
    BITCOIND_ZMQ_PORT=19332
    COMMAND_TEXT="--bitcoin.testnet"
    elif [[ $CHAIN == "regtest" ]]; then
    BITCOIND_RPC_PORT=28332
    BITCOIND_ZMQ_PORT=29332
    COMMAND_TEXT="--bitcoin.regtest"
fi

BITCOIND_NAME="bitcoindrpc-$CHAIN"

# # if this is the first time we're running, generate the certificate
# if [ ! -f /config/tls.cert ]; then
#     echo "Generating special TLS certificates for LND and lnd-cli web."
#     #put the LND_CERTIFICATE_HOSTNAME env in there.
#     openssl ecparam -genkey -name prime256v1 -out /config/tls.key
#     openssl req -new -sha256 -key /config/tls.key -out /config/csr.csr -subj "/CN=$LND_CERTIFICATE_HOSTNAME/CN=localhost/O=lnd"
#     openssl req -x509 -sha256 -days 36500 -key /config/tls.key -in /config/csr.csr -out /config/tls.cert

#     #copy the cert to /root/.lnd/tls.cert so lncli command line works correctly.

#     rm /config/csr.csr
# fi

lnd --lnddir=/root/.lnd \
--configfile=/root/.lnd/lnd.conf \
--adminmacaroonpath=/macaroons/admin.macaroon \
--bitcoind.rpchost="$BITCOIND_NAME:$BITCOIND_RPC_PORT" \
--bitcoind.zmqpubrawblock="$BITCOIND_NAME:$BITCOIND_ZMQ_BLOCK_PORT" \
--bitcoind.zmqpubrawtx="$BITCOIND_NAME:$BITCOIND_ZMQ_TX_PORT" \
--logdir="/var/logs/lnd" \
--bitcoin.node="bitcoind" --bitcoin.active "$COMMAND_TEXT"

#--bitcoin.chaindir="/bitcoin/data" \
# --tlscertpath=/config/tls.cert \
# --tlskeypath=/config/tls.key \