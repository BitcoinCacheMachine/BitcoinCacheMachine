FROM bcm-tor:latest
RUN apt-get install -y dnsmasq
RUN mkdir -p /tftp/pxeboot
ADD dnsmasq.conf /etc/dnsmasq.conf
ADD torrc /etc/tor/torrc
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]