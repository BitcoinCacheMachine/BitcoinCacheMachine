#!/bin/bash


docker kill wasabi
sleep 3
docker system prune -f
