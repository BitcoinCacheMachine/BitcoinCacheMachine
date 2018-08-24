FROM ubuntu:bionic
RUN apt update
RUN apt install -y dnsmasq
ADD dnsmasq.conf /etc/dnsmasq.conf
# RUN chmod 0644 /etc/dnsmasq.conf
# RUN chown root:root /etc/dnsmasq.conf
CMD ["dnsmasq"]