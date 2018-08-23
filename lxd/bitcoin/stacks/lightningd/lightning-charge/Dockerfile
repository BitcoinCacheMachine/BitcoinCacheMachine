FROM node:8.9-slim as builder

RUN apt-get update && apt-get install -y --no-install-recommends autoconf automake build-essential git libtool libgmp-dev \
  libsqlite3-dev python python3 wget zlib1g-dev

ARG TESTRUNNER
ARG LIGHTNINGD_VERSION=v0.6

# RUN git clone https://github.com/ElementsProject/lightning.git /opt/lightningd \
#     && cd /opt/lightningd \
#     && git checkout $LIGHTNINGD_VERSION \
#     && DEVELOPER=$TESTRUNNER ./configure \
#     && make

WORKDIR /opt/charged

COPY package*.json ./
RUN npm install \
   && test -n "$TESTRUNNER" || { \
      cp -r node_modules node_modules.dev \
      && npm prune --production \
      && mv -f node_modules node_modules.prod \
      && mv -f node_modules.dev node_modules; }

# https://github.com/npm/npm/issues/19356#issuecomment-361475985

COPY . .
RUN npm run dist \
    && rm -rf src \
    && test -n "$TESTRUNNER" || (rm -rf test node_modules && mv -f node_modules.prod node_modules)

FROM node:8.9-slim

WORKDIR /opt/charged
ARG TESTRUNNER
ENV HOME /tmp
ENV NODE_ENV production

RUN apt-get update && apt-get install -y --no-install-recommends inotify-tools libgmp-dev libsqlite3-dev \
      $(test -n "$TESTRUNNER" && echo jq) \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /opt/charged/bin/charged /usr/bin/charged \
    && mkdir /data \
    && ln -s /data/lightning /tmp/.lightning

COPY --from=builder /opt/lightningd/cli/lightning-cli /usr/bin
COPY --from=builder /opt/lightningd/lightningd/lightning* /usr/bin/
COPY --from=builder /opt/bitcoin/bin /usr/bin
COPY --from=builder /opt/charged /opt/charged

CMD bin/docker-entrypoint.sh
EXPOSE 9112 9735