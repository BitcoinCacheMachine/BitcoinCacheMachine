#!/bin/bash

set -e

echo "Building and pushing <FIXME>/lncliweb to DockerHub."
#this step prepares custom images
docker build -t <FIXME>/lncliweb:latest .
docker push <FIXME>/lncliweb:latest
