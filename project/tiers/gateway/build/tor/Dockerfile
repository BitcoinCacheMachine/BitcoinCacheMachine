FROM bcm-gateway-01:5010/bcm-docker-base:latest

RUN apt-get update \
    && apt-get install -y tor
RUN tor --version

EXPOSE 9050
EXPOSE 9051
EXPOSE 9053

CMD [ "/usr/bin/tor" , "-f", "/etc/tor/torrc" ]
