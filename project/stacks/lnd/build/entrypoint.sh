#!/bin/bash

# exit from script if error was raised.
set -e

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

echo "lnd start script."

PORT=""
if [[ $BITCOIND_CHAIN == "mainnet" ]]; then
	echo "Configuring lnd to target bitcoin mainnet."
	PORT=8332
elif [[ $BITCOIND_CHAIN == "testnet" ]]; then
	echo "Configuring lnd to target bitcoin testnet."
	PORT=18332
else
	echo "BITCOIND_CHAIN environment variable should be either mainnet or testnet. Quitting."
	exit 1
fi

wait-for-it -t 10 bitcoindrpc:$PORT

echo "Waiting for tcp://bitcoindrpc:28332 (ZMQ interface for tx & block notification)"
wait-for-it -t 10 bitcoindrpc:28332

# here we poll the remote bitcoind instance using the RPC interface to check
# on the sync status of bitcoind.  Only once it has fully validated the blockchain
# via the 'verificationprogress' indicator on getblockchaininfo.
# if [ -z "$LND_BITCOIND_REST_RPC_CREDENTIALS" ]
# then
#   echo "LND_BITCOIND_REST_RPC_CREDENTIALS not supplied.  Cannot perform REST calls to remote bitcoind instance.  Quitting."
#   exit 1
# fi

# BITCOIND_VERIFICATION_PROGRESS=""
# checkBitcoindSyncStatus() {

#   BITCOIND_VERIFICATION_PROGRESS=$(curl -s --user $LND_BITCOIND_REST_RPC_CREDENTIALS --data-binary '{"jsonrpc":"1.0","id":"curltext","method":"getblockchaininfo","params":[]}' -H 'content-type:text/plain;' http://bitcoind:$PORT/ | jq '.result.verificationprogress')

#   echo "bitcoind verification progress:  $BITCOIND_VERIFICATION_PROGRESS";

# }

# checkBitcoindSyncStatus #1st execution
# while [[ ! $BITCOIND_VERIFICATION_PROGRESS = 0.9* ]]; do
#    sleep 10
#    checkBitcoindSyncStatus
# done

# echo "Copying /run/secret/lnd.conf to /root/.lnd/lnd.conf"
# cp --remove-destination /run/secrets/lnd.conf /root/.lnd/lnd.conf
# chmod 0444 /root/.lnd/lnd.conf

# if this is the first time we're running, generate the certificate
if [ ! -f /config/tls.cert ]; then
	echo "Generating special TLS certificates for LND and lnd-cli web."
	#put the LND_CERTIFICATE_HOSTNAME env in there.
	openssl ecparam -genkey -name prime256v1 -out /config/tls.key
	openssl req -new -sha256 -key /config/tls.key -out /config/csr.csr -subj "/CN=$LND_CERTIFICATE_HOSTNAME/CN=localhost/O=lnd"
	openssl req -x509 -sha256 -days 36500 -key /config/tls.key -in /config/csr.csr -out /config/tls.cert

	#copy the cert to /root/.lnd/tls.cert so lncli command line works correctly.

	rm /config/csr.csr
fi

echo "Starting: lnd --lnddir=/root/.lnd --configfile=/run/secrets/lnd.conf --tlscertpath=/config/tls.cert --tlskeypath=/config/tls.key --adminmacaroonpath=/macaroons/admin.macaroon"
lnd --lnddir=/root/.lnd \
	--configfile=/root/.lnd/lnd.conf \
	--tlscertpath=/config/tls.cert \
	--tlskeypath=/config/tls.key \
	--adminmacaroonpath=/macaroons/admin.macaroon \
	--logdir="/var/logs/lnd"

# lncli --tlscertpath=/config/tls.cert --macaroonpath=/macaroons/admin.macaroon getinfo
