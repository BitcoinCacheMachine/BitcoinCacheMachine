#!/bin/bash

set -Eeuo pipefail

#BITCOIND_HOSTNAME="bitcoindrpc-$BCM_ACTIVE_CHAIN"


# torsocks is the network alias for the tor SOCKS proxy on the docker overlay network.
TOR_HOST_IP="$(getent hosts torsocks | awk '{ print $1 }')"
TOR_PROXY="$TOR_HOST_IP:9050"
TOR_CONTROL="$TOR_HOST_IP:9051"
TOR_DNS="$TOR_HOST_IP:9053"

OVERLAY_IP=$(ip addr | grep "172.16.240." | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')

touch /root/.lnd/lnd-rtl.conf
echo "[Application Options]" > /root/.lnd/lnd-rtl.conf
echo "restlisten=$OVERLAY_IP:8080" >> /root/.lnd/lnd-rtl.conf

# BITCOIND_DATAPATH_SUFFIX=
# if [[ $BCM_ACTIVE_CHAIN == "testnet" ]]; then
#     BITCOIND_DATAPATH_SUFFIX="/testnet3"
#     elif [[ $BCM_ACTIVE_CHAIN == "regtest" ]]; then
#     BITCOIND_DATAPATH_SUFFIX="/regtest"
# fi

RPC_IP=$(</root/.bitcoin/rpcip.txt)
lnd --lnddir=/root/.lnd \
--configfile=/root/.lnd/lnd.conf \
--bitcoin.node="bitcoind" \
--bitcoin.active \
--bitcoind.rpchost="$RPC_IP" \
--bitcoind.dir="/root/.bitcoin" \
--restlisten="$OVERLAY_IP:8080" \
--tor.active \
--tor.dns="soa.nodes.lightning.directory:53" \
--tor.socks="$TOR_PROXY" \
--tor.control="$TOR_CONTROL" \
--tor.streamisolation \
--tor.v3 \
--listen=localhost \
--tor.privatekeypath="/root/.lnd/tor" \
--logdir="/var/logs/lnd" \
--adminmacaroonpath="/root/.lnd_admin_macaroon/admin.macaroon" \
--readonlymacaroonpath="/root/.lnd_readonly_macaroon/readonly.macaroon" \
"$CHAIN_TEXT"

# TODO replace tor.dns with TOR DNS server once it's implemented; tor doesn't support proxy of SRV queries.
# --bitcoind.rpchost="$BITCOIND_RPC_IP:$BITCOIND_RPC_PORT" \
# --bitcoind.zmqpubrawblock="$BITCOIND_RPC_IP:$BITCOIND_ZMQ_BLOCK_PORT" \
# --bitcoind.zmqpubrawtx="$BITCOIND_RPC_IP:$BITCOIND_ZMQ_TX_PORT" \

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


#--bitcoin.chaindir="/root/.bitcoin" \
# --tlscertpath=/config/tls.cert \
# --tlskeypath=/config/tls.key \