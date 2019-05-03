ARG BCM_PRIVATE_REGISTRY
ARG BCM_DOCKER_BASE_TAG

FROM ${BCM_PRIVATE_REGISTRY}/bcm-docker-base:${BCM_DOCKER_BASE_TAG}

ENV DEBIAN_FRONTEND=noninteractive
# TODO implement method https://2019.www.torproject.org/docs/debian.html.en to
# to apt as tor.
RUN echo "deb https://deb.torproject.org/torproject.org bionic main" >> /etc/apt/sources.list
RUN echo "deb-src https://deb.torproject.org/torproject.org bionic main" >> /etc/apt/sources.list

RUN curl https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import
RUN gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add -
RUN apt update
RUN apt install -y tor deb.torproject.org-keyring

RUN tor --version

EXPOSE 9050
EXPOSE 9051
EXPOSE 9053

# COPY entrypoint.sh /entrypoint.sh
# RUN chmod +x /entrypoint.sh

COPY torrc /etc/tor/torrc
RUN chmod 0644 /etc/tor/torrc

CMD [ "/usr/bin/tor", "-f", "/etc/tor/torrc" ]
