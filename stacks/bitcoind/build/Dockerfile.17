ARG BCM_PRIVATE_REGISTRY
ARG BCM_DOCKER_BASE_TAG

FROM ${BCM_PRIVATE_REGISTRY}/bcm-docker-base:${BCM_DOCKER_BASE_TAG}

RUN set -ex \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates dirmngr gosu gnupg2 tar wget python3-pip \
	&& rm -rf /var/lib/apt/lists/*

ENV BITCOIN_VERSION 0.17.1
ENV BITCOIN_URL https://bitcoincore.org/bin/bitcoin-core-0.17.1/bitcoin-0.17.1-x86_64-linux-gnu.tar.gz
ENV BITCOIN_SHA256 53ffca45809127c9ba33ce0080558634101ec49de5224b2998c489b6d0fc2b17
ENV BITCOIN_ASC_URL https://bitcoincore.org/bin/bitcoin-core-0.17.1/SHA256SUMS.asc
ENV BITCOIN_PGP_KEY 01EA5486DE18A882D4C2684590C8019E36C2E964


# install bitcoin binaries
RUN set -ex \
	&& cd /tmp \
	&& wget -qO bitcoin.tar.gz "$BITCOIN_URL" \
	&& echo "$BITCOIN_SHA256 bitcoin.tar.gz" | sha256sum -c - \
	&& gpg2 --batch --keyserver keyserver.ubuntu.com --recv-keys "$BITCOIN_PGP_KEY" \
	&& wget -qO bitcoin.asc "$BITCOIN_ASC_URL" \
	&& gpg --verify bitcoin.asc \
	&& tar -xzvf bitcoin.tar.gz -C /usr/local --strip-components=1 --exclude=*-qt \
	&& rm -rf /tmp/*

# # create data directory
# ENV BITCOIN_DATA /root/.bitcoin
# RUN mkdir -p "$BITCOIN_DATA" \
# 	&& ln -sfn "$BITCOIN_DATA" /root/.bitcoin

VOLUME /root/.bitcoin

COPY entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh

# COPY rpcauth.py /rpcauth.py
# RUN chmod 0755 /rpcauth.py

WORKDIR /root/.bitcoin

# ZMQ BLOCKS (mainnet, testnet, regtest)
EXPOSE 9332 19332 29332

# ZMQ TX
EXPOSE 9331 19331 29331

# RPC
EXPOSE 8332 18332 28332 

# P2P
EXPOSE 8333 18333 29333

#CMD ["bitcoind"]
ENTRYPOINT ["/entrypoint.sh"]
