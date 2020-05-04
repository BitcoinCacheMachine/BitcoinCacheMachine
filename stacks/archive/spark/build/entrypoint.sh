#!/bin/bash

set -Eeuo pipefail

mkdir -p /root/.spark-wallet

SPARK_CONFIG_FILE="/root/.spark-wallet/config"
if [[ -n $SPARK_USERNAME && -n $SPARK_PASSWORD ]]; then
    touch "$SPARK_CONFIG_FILE"
    echo "login=$SPARK_USERNAME:$SPARK_PASSWORD" >> $SPARK_CONFIG_FILE
fi

# config file is read from SPARK_CONFIG_FILE
spark-wallet -i 0.0.0.0 --no-tls --pairing-url