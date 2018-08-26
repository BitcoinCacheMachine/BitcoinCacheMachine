FROM bcm-base:latest
RUN apt-get install -y dnsmasq tor
ADD dnsmasq.conf /etc/dnsmasq.conf
ADD torrc /etc/tor/torrc
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]