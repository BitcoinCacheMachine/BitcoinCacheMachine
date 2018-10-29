#!/usr/bin/env bash

# set the working directory to the location where the script is located
cd "$(dirname "$0")"

docker pull ubuntu:bionic
docker build -t <FIXME>/bcm-base:latest .
docker push "<FIXME>/bcm-base:latest"
