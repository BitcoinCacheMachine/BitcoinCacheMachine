#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")" 

bash -c ./gateway/up_lxc_gateway.sh

bash -c ./kafka/up_lxc_kafka.sh

bash -c ./ui_dmz/up_lxc_ui_dmz.sh