FROM ubuntu:bionic

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y rsync \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
        
# Setup rsync
EXPOSE 873

CMD ["rsync_server"]
ENTRYPOINT ["/entrypoint.sh"]
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod 744 /entrypoint.sh