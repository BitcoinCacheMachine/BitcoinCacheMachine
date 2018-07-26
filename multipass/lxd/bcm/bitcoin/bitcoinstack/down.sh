#!/bin/bash

set -e

docker stack rm btcstack

sleep 5

docker system prune -f
