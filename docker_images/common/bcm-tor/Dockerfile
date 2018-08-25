FROM bcm-base:latest
RUN apt-get install -y tor && apt-get purge && apt-get autoremove && apt-get clean
CMD [ "tor" ]