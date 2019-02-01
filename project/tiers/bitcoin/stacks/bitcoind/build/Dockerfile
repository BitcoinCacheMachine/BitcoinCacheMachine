FROM bcm-gateway-01:5010/bcm-docker-base:latest

# this was taken from https://github.com/NicolasDorier/docker-bitcoin/tree/master/core

# RUN groupadd -r bitcoin && useradd -r -m -g bitcoin bitcoin

RUN set -ex \
	&& apt-get update \
	&& apt-get install -qq --no-install-recommends ca-certificates dirmngr gosu gnupg2 tar wget iproute2 \
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

# create data directory
ENV BITCOIN_DATA /data
RUN mkdir "$BITCOIN_DATA" \
	&& ln -sfn "$BITCOIN_DATA" /root/.bitcoin

VOLUME /data
# && chown -R bitcoin:bitcoin "$BITCOIN_DATA" \
#	&& ln -sfn "$BITCOIN_DATA" /home/bitcoin/.bitcoin \
#&& chown -h bitcoin:bitcoin /home/bitcoin/.bitcoin
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

WORKDIR /root/.bitcoin
COPY bitcoin.conf /root/.bitcoin/bitcoin.conf

EXPOSE 8332 8333 18332 18333 18443 18444
CMD ["bitcoind"]