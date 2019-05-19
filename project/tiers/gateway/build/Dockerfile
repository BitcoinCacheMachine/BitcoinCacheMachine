ARG BCM_DOCKER_BASE_TAG

FROM ubuntu:${BCM_DOCKER_BASE_TAG}

RUN apt-get update \
    && apt-get install -y wait-for-it git iproute2 curl dnsutils wait-for-it iputils-ping iproute2 duplicity ca-certificates net-tools \
    && rm -rf /var/lib/apt/lists/*
