#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

RESULT=$(lxc image list --format csv -c lf | grep "^," | cut -d "," -f 2)

for LXC_IMAGE_ID in $RESULT
do
    echo "INFO: Removing dangling LXC image with ID '$LXC_IMAGE_ID'."
    lxc image rm "$LXC_IMAGE_ID"
done
