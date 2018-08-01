#!/bin/bash

set -e

echo "Starting local TOR instance for lightningd configuration"

/usr/bin/tor -f /etc/tor/torrc &

sleep 30

# call oroginal entrypoint.sh that comes with image.
bash -c /entrypoint.sh