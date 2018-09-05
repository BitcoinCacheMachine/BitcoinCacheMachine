#!/bin/bash

lxc exec bcm-gateway -- docker stack rm privateregistry

lxc exec bcm-gateway -- docker system prune -f & >>/dev/null