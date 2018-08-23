#!/bin/bash
set -eu

echo "Copying /data/bitcoin.conf to /root/.bitcoin/bitcoin.conf so the bitcoin-cli works without issue"
mkdir -p /root/.bitcoin
cp /data/bitcoin.conf /root/.bitcoin/bitcoin.conf

bitcoind -conf=/data/bitcoin.conf -datadir=/data