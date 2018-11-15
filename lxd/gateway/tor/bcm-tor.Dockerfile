FROM bcm-gateway-01:5005/bcm-base:latest
RUN apt-get install -y tor
RUN tor --version

EXPOSE 9050
EXPOSE 9053

CMD [ "/usr/bin/tor" , "-f", "/etc/tor/torrc" ]