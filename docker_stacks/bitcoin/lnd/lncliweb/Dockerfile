
FROM tyzbit/lncli-web

RUN npm install -g node-wait-for-it

COPY ./entrypoint.sh /entrypoint.sh

WORKDIR /lncli-web

RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
