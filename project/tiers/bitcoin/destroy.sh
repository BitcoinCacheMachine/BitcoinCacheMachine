#!/bin/bash

set -Eeuo pipefail
cd "$(dirname "$0")"


bash -c ./bitcoind_stack_destroy.sh