FROM node:8.9-slim as builder

ARG STANDALONE

RUN apt-get update && apt-get install -y --no-install-recommends git \
    $([ -n "$STANDALONE" ] || echo "autoconf automake build-essential libtool libgmp-dev \
    libsqlite3-dev python python3 wget zlib1g-dev")

ARG TESTRUNNER

RUN git clone https://github.com/ElementsProject/lightning-charge /opt/charged
WORKDIR /opt/charged
RUN git checkout tags/v0.4.7

#COPY package.json npm-shrinkwrap.json ./
RUN npm install \
    && test -n "$TESTRUNNER" || { \
    cp -r node_modules node_modules.dev \
    && npm prune --production \
    && mv -f node_modules node_modules.prod \
    && mv -f node_modules.dev node_modules; }

#COPY . .
RUN npm run dist \
    && rm -rf src \
    && test -n "$TESTRUNNER" || (rm -rf test node_modules && mv -f node_modules.prod node_modules)

FROM node:8.9-slim

WORKDIR /opt/charged
ARG TESTRUNNER
ENV HOME /tmp
ENV NODE_ENV production
ARG STANDALONE
ENV STANDALONE=$STANDALONE

RUN ([ -n "$STANDALONE" ] || ( \
    apt-get update && apt-get install -y --no-install-recommends inotify-tools libgmp-dev libsqlite3-dev \
    $(test -n "$TESTRUNNER" && echo jq))) \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /opt/charged/bin/charged /usr/bin/charged \
    && mkdir /data \
    && ln -s /data/lightning /tmp/.lightning

#COPY --from=builder /opt/bin /usr/bin
COPY --from=builder /opt/charged /opt/charged

ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 9112

RUN ln -s "$(which nodejs)" /usr/local/bin/node

ENTRYPOINT [ "/entrypoint.sh" ]
