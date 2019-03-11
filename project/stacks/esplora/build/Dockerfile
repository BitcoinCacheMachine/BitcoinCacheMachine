FROM node
#FROM bcm-gateway-01:5010/bcm-docker-base:latest

RUN apt-get update && apt-get install -y nodejs
RUN git clone https://github.com/Blockstream/esplora /root/esplora
WORKDIR /root/esplora
RUN git checkout tags/esplora_v2.10

RUN npm install

ADD ./entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]