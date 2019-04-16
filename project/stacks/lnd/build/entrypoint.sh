#!/bin/bash

set -Eeuo pipefail

BITCOIND_HOSTNAME="bitcoindrpc-$BCM_ACTIVE_CHAIN"

LOCAL_GW_LXD_HOST_IP="$(getent hosts "$LXC_HOSTNAME" | awk '{ print $1 }')"
TOR_PROXY="$LOCAL_GW_LXD_HOST_IP:9050"
TOR_CONTROL="$LOCAL_GW_LXD_HOST_IP:9051"
OVERLAY_NETWORK_IP=$(ip addr | grep "172.16.240." | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

touch /root/.lnd/lnd-rtl.conf
echo "restlisten=$OVERLAY_NETWORK_IP:8080" > /root/.lnd/lnd-rtl.conf

lnd --lnddir=/root/.lnd \
--configfile=/root/.lnd/lnd.conf \
--bitcoind.dir="/bitcoin/data" \
--bitcoind.rpcuser="$BITCOIND_RPC_USERNAME" \
--bitcoind.rpcpass="$BITCOIND_RPC_PASSWORD" \
--bitcoind.rpchost="$BITCOIND_HOSTNAME:$BITCOIND_RPC_PORT" \
--bitcoind.zmqpubrawblock="$BITCOIND_HOSTNAME:$BITCOIND_ZMQ_BLOCK_PORT" \
--bitcoind.zmqpubrawtx="$BITCOIND_HOSTNAME:$BITCOIND_ZMQ_TX_PORT" \
--restlisten="$OVERLAY_NETWORK_IP:8080" \
--tor.active \
--tor.socks="$TOR_PROXY" \
--tor.control="$TOR_CONTROL" \
--tor.dns="$LOCAL_GW_LXD_HOST_IP:9053" \
--tor.streamisolation \
--tor.v3 \
--logdir="/var/logs/lnd" \
--bitcoin.node="bitcoind" --bitcoin.active "$CHAIN_TEXT"

# --adminmacaroonpath=/macaroons/admin.macaroon \
# --readonlymacaroonpath=/macaroons/readonly.macaroon \
# # error function is used within a bash function in order to send the error
# # message directly to the stderr output and exit.
# error() {
#     echo "$1" >/dev/stderr
#     exit 0
# }

# # return is used within bash function in order to return the value.
# return() {
#     echo "$1"
# }

# #BITCOIND_RPC_PORT="8332"
# BITCOIND_ZMQ_BLOCKS_PORT="9332"
# COMMAND_TEXT="--bitcoin.mainnet"
# BITCOIND_ZMQ_BLOCK_PORT=
# BITCOIND_ZMQ_TX_PORT=

# # mainnet ZMQ, testnet ZMQ, regtest ZMQ
# EXPOSE 9332 19332 29332
# if [[ $CHAIN == "testnet" ]]; then
#     BITCOIND_RPC_PORT=18332
#     BITCOIND_ZMQ_PORT=19332
#     COMMAND_TEXT="--bitcoin.testnet"
#     elif [[ $CHAIN == "regtest" ]]; then
#     BITCOIND_RPC_PORT=28332
#     BITCOIND_ZMQ_PORT=29332
#     COMMAND_TEXT="--bitcoin.regtest"
# fi

# BITCOIND_NAME="bitcoindrpc-$CHAIN"

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


#--bitcoin.chaindir="/bitcoin/data" \
# --tlscertpath=/config/tls.cert \
# --tlskeypath=/config/tls.key \