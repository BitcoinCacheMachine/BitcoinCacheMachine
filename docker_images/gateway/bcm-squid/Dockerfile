FROM farscapian/bcm-base:latest
RUN apt-get install -y squid && apt-get purge && apt-get clean
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
EXPOSE 3128
ENTRYPOINT [ "/entrypoint.sh" ]