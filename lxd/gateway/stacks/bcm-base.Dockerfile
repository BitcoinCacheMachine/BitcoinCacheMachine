FROM bcm-gateway-01:443/bcm-bionic-base:latest
RUN apt-get update
RUN apt-get install -y wait-for-it iproute2 curl
