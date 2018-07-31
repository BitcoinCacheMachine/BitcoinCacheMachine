#!/bin/bash
set -e

# run tor process using torrc config file
# which should be configured to run as daemon
#echo "Starting tor on $HOSTNAME"
#tor -f /etc/tor/torrc

# wait for tor to come online
#wait-for-it -t 0 127.0.0.1:9050
#wait-for-it -t 0 127.0.0.1:9051

echo "Copying /data/bitcoin.conf to /root/.bitcoin/bitcoin.conf so the bitcoin-cli works without issue"
mkdir -p /root/.bitcoin
cp /data/bitcoin.conf /root/.bitcoin/bitcoin.conf

bitcoind -conf=/data/bitcoin.conf -datadir=/data