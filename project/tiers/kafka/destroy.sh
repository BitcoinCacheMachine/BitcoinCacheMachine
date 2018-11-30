#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

# remove stateless docker stacks.
bash -c ./stacks/connect/destroy_kafka_connect.sh
bash -c ./stacks/rest/destroy_kafka_rest.sh
bash -c ./stacks/schemareg/destroy_schema-registry.sh

# destroy the brokers and zookeeper stacks which are deployed as distinct docker services
bash -c ./broker/destroy_lxc_broker.sh
bash -c ./zookeeper/destroy_zookeeper.sh