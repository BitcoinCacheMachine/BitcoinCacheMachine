FROM bcm-gateway-01:5010/bcm-docker-base:latest

RUN apt-get update
RUN apt-get install -y autoconf automake build-essential git libtool libgmp-dev libsqlite3-dev python python3 net-tools zlib1g-dev
RUN git clone https://github.com/ElementsProject/lightning.git /root/lightning
WORKDIR /root/lightning
RUN ./configure
RUN make

COPY clightning.conf /root/.lightning/config
ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh



ENTRYPOINT [ "/entrypoint.sh" ]
