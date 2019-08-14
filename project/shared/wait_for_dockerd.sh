#!/bin/bash

set -Eeuo pipefail

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

echo "Waiting for dockerd on LXC host '$LXC_HOST'."

if lxc list --format csv -c=n | grep -q "$LXC_HOST"; then
    while true; do
        if lxc info $LXC_HOST | grep -q docker0; then
            echo "dockerd on LXC host '$LXC_HOST' is running."
            break
        else
            sleep 1
            printf "."
        fi
    done
    
    echo ""
fi