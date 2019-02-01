FROM bcm-gateway-01:5010/bcm-docker-base:latest
RUN apt-get update
RUN apt-get install -y wait-for-it iproute2 curl dnsutils wait-for-it iputils-ping
