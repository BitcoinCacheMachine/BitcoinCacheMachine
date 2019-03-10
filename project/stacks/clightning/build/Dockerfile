FROM bcm-gateway-01:5010/bcm-docker-base:latest

RUN apt-get update
RUN apt-get install -y autoconf automake build-essential git libtool libgmp-dev libsqlite3-dev python python3 net-tools zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/ElementsProject/lightning.git /root/lightning
WORKDIR /root/lightning
RUN git checkout tags/v0.7.0
RUN ./configure
RUN make

WORKDIR /root/.lightning
ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# include the lightning CLI in the PATH
ENV PATH="/root/lightning/cli:${PATH}"

ENTRYPOINT [ "/entrypoint.sh" ]