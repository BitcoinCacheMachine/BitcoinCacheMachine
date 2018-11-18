#!/usr/bin/env bash

set -eu
cd "$(dirname "$0")"

# At a high level, this script works towards getting active bcm-gateway docker daemons
# running on each cluster member. The cluster master '01' is responsible for bootstrapping
# docker images to minimize network traffic. Subsequent dockerd are configured to pull
# deocker images from '01'.  '02' also hosts a docker mirror for local redundancy, but it 
# pulls from 01. So if there's an issue with 01, we can't do updates. 02 can still service
# existing images to other dockerd instances.

bash -c ./host_template/up_lxc_host_template.sh

bash -c ./gateway/up_lxc_gateway.sh

bash -c ./kafka/up_lxc_kafka.sh
