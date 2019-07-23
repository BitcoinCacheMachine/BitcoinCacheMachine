FROM node:latest

RUN git clone https://github.com/shesek/spark-wallet /spark-wallet
WORKDIR /spark-wallet
RUN npm run dist:npm
RUN ./dist/cli.js --ln-path /root/.lightning

#RUN npm install -g spark-wallet

ADD ./entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh

WORKDIR /root/.lightning

ENTRYPOINT [ "/entrypoint.sh" ]