#!/bin/bash

 pipefail

LXC_HOST=

for i in "$@"; do
    case $i in
        --container-name=*)
            LXC_HOST="${i#*=}"
            shift # past argument=value
        ;;
        *)
            # unknown option
        ;;
    esac
done

echo "Waiting for dockerd to come online on LXC host '$LXC_HOST'"

if lxc list | grep -q "$LXC_HOST"; then
    while true; do
        if [[ "$(lxc exec $LXC_HOST -- systemctl is-active docker)" == "active" ]]; then
            break
        fi
        
        sleep 1
        printf "."
    done
fi

echo ""