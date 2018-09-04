FROM farscapian/bcm-base:latest
RUN apt-get install -y dnsmasq && apt-get purge && apt-get clean
ENTRYPOINT ["dnsmasq", "-d"]
EXPOSE 53 53/udp
ADD dnsmasq.conf /etc/dnsmasq.conf