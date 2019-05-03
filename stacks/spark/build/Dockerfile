FROM node

RUN npm install -g spark-wallet

WORKDIR /root/.lightning
ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]