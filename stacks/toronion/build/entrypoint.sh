#!/bin/bash

set -Eeux

echo "inside tor"

ip addr
route -n

/usr/bin/tor -f /etc/tor/torrc