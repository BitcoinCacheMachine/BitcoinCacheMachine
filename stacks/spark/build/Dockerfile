FROM node:latest

RUN npm install -g spark-wallet

ADD ./entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh

WORKDIR /root/.lightning

ENTRYPOINT [ "/entrypoint.sh" ]