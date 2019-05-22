ARG BCM_PRIVATE_REGISTRY
ARG BCM_DOCKER_BASE_TAG

FROM ${BCM_PRIVATE_REGISTRY}/bcm-docker-base:${BCM_DOCKER_BASE_TAG}

#ENV DEBIAN_FRONTEND=noninteractive
# TODO implement method https://2019.www.torproject.org/docs/debian.html.en to
# to apt as tor.
RUN echo "deb https://deb.torproject.org/torproject.org bionic main" >> /etc/apt/sources.list
RUN echo "deb-src https://deb.torproject.org/torproject.org bionic main" >> /etc/apt/sources.list

RUN curl https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import
RUN gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -

RUN apt-get update
RUN apt-get install -y tor deb.torproject.org-keyring

# SOCKS5, Control Port, DNS
EXPOSE 9050 9051 9053


COPY entrypoint.sh /entrypoint.sh
RUN chmod 0755 /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]


