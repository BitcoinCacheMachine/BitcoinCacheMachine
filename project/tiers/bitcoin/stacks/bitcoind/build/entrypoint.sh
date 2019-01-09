#!/bin/bash

set -x
echo "Got into start script."
if [[ -f /secrets/bitcoin.conf ]]; then
	echo "Copying /secrets/bitcoin.conf to /home/bitcoin/.bitcoin/bitcoin.conf"
	cp /secrets/bitcoin.conf /home/bitcoin/.bitcoin/bitcoin.conf
	chown -R bitcoin:bitcoin /home/bitcoin/.bitcoin
fi

echo "Starting bitcoind with 'bitcoind -conf=/home/bitcoin/bitcoin.conf -datadir=/data'"
bitcoind -conf=/home/bitcoin/bitcoin.conf -datadir=/data
