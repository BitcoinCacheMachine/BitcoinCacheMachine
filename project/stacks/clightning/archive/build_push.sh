#!/bin/bash

set -e

echo "Building and pushing <FIXME>/lightningd:0.6 to DockerHub."
#this step prepares custom images
docker build -t <FIXME>/lightningd:0.6 .
docker push <FIXME>/lightningd:0.6
