#!/bin/bash

set -eu

cd "$(dirname "$0")"


cat stack_options.csv | while read line; do
    IFS=, read -ra values <<< $line
    STACK=${values[0]}
    CERTCN=${values[1]} 
    BCMDEPLOYMENTVAR=${values[2]}
    TCPPORT=${values[3]}

    echo "$STACK, $CERTCN, $BCMDEPLOYMENTVAR, $TCPPORT"

    if [ eval $BCMDEPLOYMENTVAR = "true" ]; then
        echo "Wating for 192.168.4.1:$TCPPORT"
        lxc exec $BCM_LXC_GATEWAY_CONTAINER_NAME -- wait-for-it -t 0 "192.168.4.1:$TCPPORT"
    fi
done