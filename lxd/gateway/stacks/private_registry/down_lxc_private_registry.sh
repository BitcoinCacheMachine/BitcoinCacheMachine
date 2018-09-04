#!/bin/bash

lxc exec bcm-gateway -- docker stack rm privateregistry

lxc exec bcm-gateway -- sleep 10 && docker system prune -f & >>/dev/null