#!/bin/bash


docker build -t wasabi:latest .

docker run -d -e HTTP_PROXY=http://127.0.10.1:9050 -e HTTPS_PROXY=http://127.0.10.1:9050 --name wasabi -v ~/git/temp:/wasabigitrepo --dns=127.0.10.1 wasabi:latest
docker exec -t wasabi /build_wasabi.sh

# install requirements
