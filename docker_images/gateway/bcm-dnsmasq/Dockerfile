FROM ubuntu:latest
RUN apt-get update && apt-get install -y dnsmasq && apt-get purge && apt-get clean
RUN mkdir -p /tftp/pxeboot
ADD dnsmasq.conf /etc/dnsmasq.conf
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]