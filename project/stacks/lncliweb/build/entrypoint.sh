#!/bin/bash

set -e

echo "lncli-web start script."

# echo "Redirecting stdout and stderr to syslog host $SYSLOG_DESTINATION on port $SYSLOG_PORT using tag $SYSLOG_TAG."
# exec 1> >(logger -s -n $SYSLOG_DESTINATION --port $SYSLOG_PORT --tcp -t $SYSLOG_TAG) 2>&1

echo "Waiting for /macaroons/admin.macaroon and /config/tls.cert to appear..."
while [ ! -f "/macaroons/admin.macaroon" ]
do
    sleep 5
done

echo "/config/tls.cert not found.  Waiting 3 seconds."
while [ ! -f "/config/tls.cert" ]
do
    sleep 2
done

echo "Waiting on lnd grpc interface to respond. It could take several hours while bitcoind and lnd do their thing (block download/validation/indexing/graph creation, etc.)"
wait-for-it -t 10 lndrpc:10009

echo "launching node server"
node server
