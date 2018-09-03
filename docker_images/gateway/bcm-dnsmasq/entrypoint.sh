#!/bin/bash

tor &

wait-for-it 127.0.0.1:9050

# start dnsmasq
dnsmasq -d