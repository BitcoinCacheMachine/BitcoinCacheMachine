#!/bin/bash

# wait for it to initiailize
wait-for-it -t 0 torproxy:9050

# start dnsmasq
dnsmasq -d