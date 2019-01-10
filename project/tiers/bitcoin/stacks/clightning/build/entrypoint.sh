#!/bin/bash

set -ex

echo "Starting clightning configuration"
lightningd --conf=/root/.lightning/config --bind-addr="127.0.0.1:9735" --proxy="$GATEWAY_IP:9050" --addr="autotor:$GATEWAY_IP:9051" --log-level=debug
