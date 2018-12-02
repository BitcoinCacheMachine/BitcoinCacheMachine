#!/usr/bin/env bash

set -Eeuox pipefail

echo "Copying /setcrets/bitcoin.conf to /root/.bitcoin/bitcoin.conf so the bitcoin-cli works without issue"
mkdir -p /root/.bitcoin

cp /secrets/bitcoin.conf /root/.bitcoin/bitcoin.conf

cd /root/.bitcoin

echo "Starting bitcoind with 'bitcoind -conf=/data/bitcoin.conf -datadir=/bitcoindata'"
bitcoind -conf=/data/bitcoin.conf -datadir=/bitcoindata