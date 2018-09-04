#!/bin/bash

set -e

echo "Starting local TOR instance for lightningd configuration"

/usr/bin/tor -f /etc/tor/torrc &

sleep 15

lightningd --conf=/root/.lightning/config --bind-addr="127.0.0.1:9735" --proxy="127.0.0.1:9050" --addr="autotor:127.0.0.1:9051" --log-level=debug