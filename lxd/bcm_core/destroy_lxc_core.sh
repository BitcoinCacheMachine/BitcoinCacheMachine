#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

./kafka/destroy_lxc_kafka.sh

./gateway/destroy_lxc_gateway.sh

./host_template/destroy_lxc_host_template.sh
