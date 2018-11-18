#!/bin/bash

set -eu
cd "$(dirname "$0")"

bash -c ./kafka/destroy_lxc_kafka.sh

bash -c ./gateway/destroy_lxc_gateway.sh

bash -c ./host_template/destroy_lxc_host_template.sh