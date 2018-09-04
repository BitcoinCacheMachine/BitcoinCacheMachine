#!/bin/bash

# set the working directory to the location where the script is located
# since all file references are relative to this script
cd "$(dirname "$0")"


docker build -t farscapian/bcm-squid:latest .
docker push farscapian/bcm-squid:latest