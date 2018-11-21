FROM bcm-docker-base:latest
RUN apt-get update 
RUN apt-get install -y tor
COPY ./build_wasabi.sh /build_wasabi.sh
RUN chmod +x /build_wasabi.sh

RUN mkdir /wasabigitrepo
WORKDIR /wasabigitrepo

COPY ./wgetrc /root/.wgetrc

VOLUME /wasabigitrepo

COPY ./torrc /etc/tor/torrc





CMD [ "tor" ]