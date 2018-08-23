#!/bin/bash

set -e

echo "Building and pushing farscapian/lncliweb to DockerHub."
#this step prepares custom images
docker build -t farscapian/lncliweb:latest .
docker push farscapian/lncliweb:latest
