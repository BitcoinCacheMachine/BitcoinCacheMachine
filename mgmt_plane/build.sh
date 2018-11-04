#!/bin/bash

set -eu

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

docker build -t bcm-trezor:latest .
