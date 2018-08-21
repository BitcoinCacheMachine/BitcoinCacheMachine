#!/bin/bash

set -e

echo "Building and pushing farscapian/lightningd:0.6 to DockerHub."
#this step prepares custom images
docker build -t farscapian/lightningd:0.6 .
docker push farscapian/lightningd:0.6
