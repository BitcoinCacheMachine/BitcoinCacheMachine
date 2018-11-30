#!/usr/bin/env bash

set -Eeuo pipefail
cd "$(dirname "$0")" 


# bring up the docker UI STACKS.
# TODO eventually we'll hide these behind a VPN gateway (so you first have to VPN eg wireguard)
# into your data center BEFORE being able to access these services. This could be implemented
# from a docker container.
bash -c ./stacks/connect_ui/up_connect_ui.sh
bash -c ./stacks/schema_registry_ui/up_schema_registry_ui.sh
bash -c ./stacks/topics_ui/up_topics_ui.sh
#bash -c ./stacks/control_center/up_control_center.sh


