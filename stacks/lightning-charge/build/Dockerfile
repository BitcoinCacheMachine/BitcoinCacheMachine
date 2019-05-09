ARG BCM_PRIVATE_REGISTRY
ARG BCM_DOCKER_BASE_TAG

FROM ${BCM_PRIVATE_REGISTRY}/bcm-docker-base:${BCM_DOCKER_BASE_TAG}

RUN apt-get update && apt-get install -y --no-install-recommends git autoconf automake build-essential libtool libgmp-dev libsqlite3-dev python python3 wget zlib1g-dev inotify-tools 

RUN git clone https://github.com/ElementsProject/lightning-charge /opt/charged
WORKDIR /opt/charged
RUN git checkout tags/v0.4.7

RUN apt-get install -y --no-install-recommends curl python-software-properties
RUN curl -sL https://deb.nodesource.com/setup_11.x | bash -
RUN apt-get install -y --no-install-recommends nodejs

RUN npm install
RUN npm run dist && rm -rf src 

WORKDIR /opt/charged

RUN rm -rf /var/lib/apt/lists/* \
    && ln -s /opt/charged/bin/charged /usr/bin/charged \
    && mkdir /data \
    && ln -s /data/lightning /tmp/.lightning

ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 9112

ENTRYPOINT [ "/entrypoint.sh" ]