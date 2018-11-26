#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")" 

# This brings up 'bcm-gateway' and 'bcm-kafka' LXC hosts and populates
# the respective docker daemons.

bash -c ./host_template/up_lxc_host_template.sh

bash -c ./gateway/up_lxc_gateway.sh

bash -c ./kafka/up_lxc_kafka.sh