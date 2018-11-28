#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

./ui_dmz/destroy_lxc_ui_dmz.sh

./kafka/destroy_lxc_kafka.sh

./gateway/destroy_lxc_gateway.sh