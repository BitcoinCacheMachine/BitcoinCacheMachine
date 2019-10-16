ARG BASE_IMAGE

FROM ${BASE_IMAGE}

RUN apt-get update \
    && apt-get install -y wait-for-it git iproute2 curl dnsutils wait-for-it iputils-ping iproute2 duplicity ca-certificates net-tools \
    && rm -rf /var/lib/apt/lists/*
