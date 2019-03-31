ARG BCM_PRIVATE_REGISTRY
ARG BCM_DOCKER_BASE_TAG

FROM ${BCM_PRIVATE_REGISTRY}/bcm-docker-base:${BCM_DOCKER_BASE_TAG}

RUN apt-get update \
    && apt-get install -y tor
RUN tor --version

EXPOSE 9050
EXPOSE 9051
EXPOSE 9053

CMD [ "/usr/bin/tor" , "-f", "/etc/tor/torrc" ]
