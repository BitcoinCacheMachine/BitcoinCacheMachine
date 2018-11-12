FROM bcm-base:latest
RUN apt-get install -y dnsmasq
EXPOSE 53 53/udp
ADD dnsmasq.conf /etc/dnsmasq.conf
CMD ["dnsmasq", "-d"]