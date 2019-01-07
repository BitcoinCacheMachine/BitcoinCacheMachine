#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"

$PASSWORD=$(bcm pass get --name="")

git push .
