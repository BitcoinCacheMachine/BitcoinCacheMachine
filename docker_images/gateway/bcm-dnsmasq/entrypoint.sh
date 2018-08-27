#!/bin/bash

# start local TOR instance
tor &

# wait for tor to start
wait-for-it -t 0 127.0.0.1:9050

# start dnsmasq
dnsmasq -d