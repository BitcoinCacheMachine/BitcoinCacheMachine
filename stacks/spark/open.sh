#!/bin/bash

# open.sh opens the app for the end user.

source ./env.sh

ENDPOINT_IP="$(bcm get-ip)"
wait-for-it -t 0 "$ENDPOINT:$SERVICE_PORT"

# let's the the pariing URL from the container output
PAIRING_OUTPUT_URL=$(lxc exec "$BCM_GATEWAY_HOST_NAME" --  docker service logs "spark-$BCM_ACTIVE_CHAIN""_spark" | grep 'Pairing URL: ' | awk '{print $5}')
SPARK_URL=${PAIRING_OUTPUT_URL/0.0.0.0/$ENDPOINT_IP}

xdg-open "$SPARK_URL" &
