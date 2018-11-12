FROM bcm-base:latest
RUN apt-get install -y tor
RUN tor --version
COPY ./torrc /etc/tor/

EXPOSE 9050
EXPOSE 9053

CMD [ "/usr/bin/tor" , "-f", "/etc/tor/torrc" ]