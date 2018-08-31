FROM bcm-base:latest
RUN apt-get install -y squid
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 3128
ENTRYPOINT [ "/entrypoint.sh" ]