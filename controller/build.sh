#!/bin/bash

set -Eeuox pipefail
cd "$(dirname "$0")"

if ! docker image list | grep -q "bcm-trezor"; then
	# make sure the container is up-to-date, but don't display
	echo "Updating docker image bcm-trezor:latest ..."
	docker build -t bcm-trezor:latest .
fi

docker build -t bcm-trezor:latest .
