FROM elementsproject/lightningd
RUN apk add --update tor
#RUN apk add wait-for-it
ADD ./docker-entrypoint.sh /docker-entrypoint.sh
ADD ./torrc /etc/tor/torrc
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT [ "/docker-entrypoint.sh" ]