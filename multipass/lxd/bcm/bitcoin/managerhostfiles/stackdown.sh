#!/bin/bash

docker stack rm bitcoinstack

sleep 5

docker system prune -f

