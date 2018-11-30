#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

bash -c ./stacks/connect_ui/destroy_connect_ui.sh
bash -c ./stacks/control_center/destroy_control_center.sh
bash -c ./stacks/schema_registry_ui/destroy_schema_registry_ui.sh
bash -c ./stacks/topics_ui/destroy_topics_ui.sh