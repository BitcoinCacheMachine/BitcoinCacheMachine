#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"

docker build -t <FIXME>/bcm-squid:latest .
docker push <FIXME>/bcm-squid:latest