FROM bcm-gateway-01:5010/bcm-docker-base:latest

RUN apt-get update
RUN apt-get install -y autoconf automake build-essential git libtool libgmp-dev libsqlite3-dev python python3 net-tools zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ElementsProject/lightning.git /root/lightning
WORKDIR /root/lightning
RUN ./configure
RUN make

WORKDIR /root/.lightning
ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# RUN cp /root/lightning/cli/lightning-cli /usr/local/bin/lightning-cli
# RUN cp /root/lightning/lightningd/lightning_channeld /usr/local/bin/lightning_channeld
# RUN cp /root/lightning/lightningd/lightning_closingd /usr/local/bin/lightning_closingd
# RUN cp /root/lightning/lightningd/lightning_connectd /usr/local/bin/lightning_connectd
# RUN cp /root/lightning/lightningd/lightning_gossipd /usr/local/bin/lightning_gossipd
# RUN cp /root/lightning/lightningd/lightning_hsmd /usr/local/bin/lightning_hsmd
# RUN cp /root/lightning/lightningd/lightning_onchaind /usr/local/bin/lightning_onchaind
# RUN cp /root/lightning/lightningd/lightningd /usr/local/bin/lightningd

# RUN rm -rf /root/lighting

# RUN apt-get install tor -y
# ADD ./torrc /etc/tor/torrc

ENTRYPOINT [ "/entrypoint.sh" ]