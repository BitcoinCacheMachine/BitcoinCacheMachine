#!/bin/bash

set -Eeuo pipefail

# let's deploy a kafka node to each cluster endpoint.
KAFKA_BOOSTRAP_SERVERS="broker-01:9092"
BOOSTRAP_SERVER_MAX=3
NODE=1

for endpoint in $(bcm cluster list --endpoints); do
	HOST_ENDING=$(echo "$endpoint" | tail -c 2)

	# three brokers is more than sufficient for first contact.
	if [[ $NODE -gt 1 && $NODE -le $BOOSTRAP_SERVER_MAX ]]; then
		KAFKA_BOOSTRAP_SERVERS="$KAFKA_BOOSTRAP_SERVERS,broker-$(printf %02d "$HOST_ENDING"):9092"
	fi

	NODE=$(("$NODE" + 1))
done

export KAFKA_BOOSTRAP_SERVERS="$KAFKA_BOOSTRAP_SERVERS"
