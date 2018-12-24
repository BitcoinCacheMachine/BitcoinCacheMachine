#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

if ! snap list | grep -q lxd; then
	sudo snap remove lxd
fi
